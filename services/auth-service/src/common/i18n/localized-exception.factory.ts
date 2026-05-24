import { BadRequestException, UnauthorizedException, ForbiddenException, NotFoundException, Injectable } from '@nestjs/common';
import { I18nService } from '../i18n/i18n.service';

/**
 * Exception filter to localize error messages
 * Usage: Use this in catch blocks to return localized error messages
 */
@Injectable()
export class LocalizedExceptionFactory {
  constructor(private i18nService: I18nService) {}

  /**
   * Create a localized bad request exception
   * @param key Translation key
   * @param locale Language locale
   * @param params Optional parameters for interpolation
   */
  badRequest(key: string, locale?: string, params?: Record<string, string | number>) {
    const message = params 
      ? this.i18nService.tp(key, params, locale)
      : this.i18nService.t(key, locale);
    
    return new BadRequestException({
      statusCode: 400,
      message,
      error: 'Bad Request',
      locale: locale || 'en',
    });
  }

  /**
   * Create a localized unauthorized exception
   * @param key Translation key
   * @param locale Language locale
   */
  unauthorized(key: string, locale?: string) {
    const message = this.i18nService.t(key, locale);
    
    return new UnauthorizedException({
      statusCode: 401,
      message,
      error: 'Unauthorized',
      locale: locale || 'en',
    });
  }

  /**
   * Create a localized forbidden exception
   * @param key Translation key
   * @param locale Language locale
   */
  forbidden(key: string, locale?: string) {
    const message = this.i18nService.t(key, locale);
    
    return new ForbiddenException({
      statusCode: 403,
      message,
      error: 'Forbidden',
      locale: locale || 'en',
    });
  }

  /**
   * Create a localized not found exception
   * @param key Translation key
   * @param locale Language locale
   * @param params Optional parameters for interpolation
   */
  notFound(key: string, locale?: string, params?: Record<string, string | number>) {
    const message = params
      ? this.i18nService.tp(key, params, locale)
      : this.i18nService.t(key, locale);
    
    return new NotFoundException({
      statusCode: 404,
      message,
      error: 'Not Found',
      locale: locale || 'en',
    });
  }
}

/**
 * Usage example in a controller
 */
// @Controller('auth')
// export class AuthController {
//   constructor(
//     private readonly exceptionFactory: LocalizedExceptionFactory,
//     private readonly i18nService: I18nService,
//   ) {}

//   @Post('login')
//   async login(@Req() req: Request, @Body() loginDto: LoginDto) {
//     const locale = (req as any).i18n?.locale;

//     try {
//       // Validation
//       if (!loginDto.email) {
//         throw this.exceptionFactory.badRequest('errors.requiredField', locale);
//       }

//       if (!isValidEmail(loginDto.email)) {
//         throw this.exceptionFactory.badRequest(
//           'errors.invalidEmail',
//           locale,
//           { example: 'name@example.com' }
//         );
//       }

//       // Authentication logic
//       const user = await this.authService.findByEmail(loginDto.email);
//       if (!user) {
//         throw this.exceptionFactory.unauthorized('errors.invalidLogin', locale);
//       }

//       if (user.locked) {
//         throw this.exceptionFactory.forbidden('errors.accountLocked', locale);
//       }

//       const valid = await bcrypt.compare(loginDto.password, user.passwordHash);
//       if (!valid) {
//         throw this.exceptionFactory.unauthorized('errors.invalidLogin', locale);
//       }

//       // Return success response
//       const token = this.authService.generateToken(user);
//       return {
//         statusCode: 200,
//         message: this.i18nService.t('messages.success', locale),
//         data: { token, user },
//         locale,
//       };
//     } catch (error) {
//       throw error;
//     }
//   }
// }

/**
 * Validation error localization example
 */
// In validation pipes, localize error messages:
// @Post('invoice')
// async createInvoice(
//   @Req() req: Request,
//   @Body() createInvoiceDto: CreateInvoiceDto,
// ) {
//   const locale = (req as any).i18n?.locale;

//   const errors: Record<string, string> = {};

//   if (!createInvoiceDto.customerId) {
//     errors.customerId = this.i18nService.t('errors.requiredField', locale);
//   }

//   if (!createInvoiceDto.items || createInvoiceDto.items.length === 0) {
//     errors.items = this.i18nService.t('errors.requiredField', locale);
//   }

//   if (Object.keys(errors).length > 0) {
//     throw new BadRequestException({
//       statusCode: 400,
//       message: this.i18nService.t('errors.validationFailed', locale),
//       errors,
//       locale,
//     });
//   }

//   // Create invoice...
// }
