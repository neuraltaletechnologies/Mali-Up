package com.neuraltale.maliup

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

/**
 * Minimal classic-Bluetooth (RFCOMM / SPP) bridge for ESC/POS receipt
 * printers — the cheap 58mm/80mm handheld printers sold in TZ shops.
 *
 * Only lists printers that are already paired in Android's Bluetooth
 * settings, so it needs BLUETOOTH_CONNECT on Android 12+ and no scan or
 * location permission. Each print opens a socket, writes, and closes, so
 * there is no long-lived connection to go stale while the app is
 * backgrounded or PIN-locked. Dart side: lib/features/printing/data/
 * bluetooth_printer_channel.dart.
 */
class BluetoothPrinterHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.neuraltale.maliup/bt_printer"

        // Standard Serial Port Profile UUID used by ESC/POS printers.
        private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

        // Cheap printers have small input buffers; feed them in slices.
        private const val CHUNK_SIZE = 512
    }

    // One print at a time — a second tap queues behind the first instead of
    // fighting it for the same RFCOMM channel.
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private val adapter: BluetoothAdapter?
        get() = (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(status())
            "bondedDevices" -> bondedDevices(result)
            "print" -> {
                val address = call.argument<String>("address")
                val bytes = call.argument<ByteArray>("bytes")
                if (address.isNullOrEmpty() || bytes == null) {
                    result.error("invalid_argument", "address and bytes are required", null)
                    return
                }
                print(address, bytes, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun hasConnectPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED

    /** "ready", "off", "permission" or "unsupported". */
    private fun status(): String {
        val a = adapter ?: return "unsupported"
        if (!hasConnectPermission()) return "permission"
        return try {
            if (a.isEnabled) "ready" else "off"
        } catch (e: SecurityException) {
            "permission"
        }
    }

    @SuppressLint("MissingPermission") // checked by status()
    private fun bondedDevices(result: MethodChannel.Result) {
        val s = status()
        if (s != "ready") {
            result.error(s, s, null)
            return
        }
        try {
            val devices = adapter!!.bondedDevices.orEmpty().map { device ->
                mapOf(
                    "name" to (device.name ?: device.address),
                    "address" to device.address,
                    "isPrinter" to isLikelyPrinter(device),
                )
            }
            result.success(devices)
        } catch (e: SecurityException) {
            result.error("permission", e.message, null)
        }
    }

    /** Most receipt printers report the "imaging" major class. */
    @SuppressLint("MissingPermission")
    private fun isLikelyPrinter(device: BluetoothDevice): Boolean = try {
        device.bluetoothClass?.majorDeviceClass == BluetoothClass.Device.Major.IMAGING
    } catch (e: SecurityException) {
        false
    }

    @SuppressLint("MissingPermission") // checked by status()
    private fun print(address: String, bytes: ByteArray, result: MethodChannel.Result) {
        val s = status()
        if (s != "ready") {
            result.error(s, s, null)
            return
        }
        executor.execute {
            var socket: BluetoothSocket? = null
            try {
                val a = adapter!!
                val device = a.getRemoteDevice(address)
                // An in-progress discovery slows RFCOMM connects badly. Needs
                // a scan permission we don't hold on newer Android — harmless
                // to skip there.
                try {
                    a.cancelDiscovery()
                } catch (ignored: SecurityException) {
                }
                socket = connect(device)
                val out = socket.outputStream
                var offset = 0
                while (offset < bytes.size) {
                    val n = minOf(CHUNK_SIZE, bytes.size - offset)
                    out.write(bytes, offset, n)
                    out.flush()
                    offset += n
                    Thread.sleep(20)
                }
                // Closing right after the last write can cut off the end of
                // the receipt on printers whose buffer is still draining.
                Thread.sleep(minOf(1500L, 300L + bytes.size / 20L))
                mainHandler.post { result.success(true) }
            } catch (e: SecurityException) {
                mainHandler.post { result.error("permission", e.message, null) }
            } catch (e: IllegalArgumentException) {
                mainHandler.post { result.error("not_found", e.message, null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("connect_failed", e.message, null) }
            } finally {
                try {
                    socket?.close()
                } catch (ignored: IOException) {
                }
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun connect(device: BluetoothDevice): BluetoothSocket {
        val secure = device.createRfcommSocketToServiceRecord(SPP_UUID)
        try {
            secure.connect()
            return secure
        } catch (e: IOException) {
            try {
                secure.close()
            } catch (ignored: IOException) {
            }
        }
        // Some printers only accept an insecure (no-MITM) RFCOMM link.
        val insecure = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID)
        try {
            insecure.connect()
            return insecure
        } catch (e: IOException) {
            try {
                insecure.close()
            } catch (ignored: IOException) {
            }
            throw e
        }
    }
}
