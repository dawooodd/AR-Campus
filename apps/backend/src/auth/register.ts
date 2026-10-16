import { Hono } from "hono";
import { prisma } from "../lib/prisma.js";
import bcrypt from "bcryptjs";

export const register = new Hono();

register.post("/api/register", async (c) => {
    const { username, NIM, password } = await c.req.json();

    if (!username || !NIM || password.length < 8) {
        return c.json({message: 'Email wajib diisi dan password minimmal 8 karakter'}, 409);
    }

    const existing = await prisma.user.findUnique({ where: { username } });
    if (existing) {
        return c.json({
            success: false,
            message: "User with this username already exists"
        }, 409);
    }

    const hashPassword = await bcrypt.hash(password, 10)

    const user = await prisma.user.create({
        data: {
            username,
            NIM,
            password: hashPassword // In a real application, make sure to hash the password before storing it
        }
    });

    return c.json({
        id: user.id,
        username: user.username,
        NIM: user.NIM,
        message: "User registered successfully"
    }, 201);
})

