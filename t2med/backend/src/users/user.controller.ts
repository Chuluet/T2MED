import { Controller, Post, Body, Get, Param, Patch, UseGuards, Req } from '@nestjs/common';
import { UserService } from './user.service';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import * as admin from 'firebase-admin';

@Controller('users')
export class UserController {
    constructor(private readonly userService: UserService) { }

    // ─── Registro ─────────────────────────────────────────────
    // Recibe todos los campos del formulario de registro
    @Post('create')
    async createUser(@Body() body: {
        email: string;
        password: string;
        name: string;
        lastName: string;
        phone: string;
        emergencyPhone?: string;
    }) {
        return this.userService.createUser(body);
    }

    // ─── Perfil ───────────────────────────────────────────────
    @Get('profile/:uid')
    @UseGuards(FirebaseAuthGuard)
    async getProfile(@Param('uid') uid: string) {
        return this.userService.getUserProfile(uid);
    }

    @Patch('profile')
    @UseGuards(FirebaseAuthGuard)
    async updateProfile(@Req() req, @Body() body: any) {
        const uid = req.user.uid;
        return this.userService.updateUserProfile(uid, body);
    }

    // ─── Recuperar contraseña ─────────────────────────────────
    // Antes: _handleLogin redirigía a ForgotPasswordPage en Flutter
    // Ahora: NestJS genera el enlace de recuperación directamente
    @Post('reset-password')
    async resetPassword(@Body() body: { email: string }) {
        return this.userService.sendPasswordReset(body.email);
    }

    // ─── Notificaciones y tokens ──────────────────────────────
    @Post('notify-emergency')
    async notifyEmergency(@Body() body: any) {
        return this.userService.notifyEmergencyContact(body);
    }

    @Post('fcm-token')
    @UseGuards(FirebaseAuthGuard)
    async registerFcmToken(@Req() req, @Body('fcmToken') fcmToken: string) {
        const uid = req.user.uid;
        return this.userService.saveFcmToken(uid, fcmToken);
    }

    @Post('test-push')
    async testPush(@Body('token') token: string) {
        const message = {
            token,
            notification: {
                title: '🔔 Prueba',
                body: 'Notificación de prueba',
            },
        };
        return admin.messaging().send(message);
    }
}