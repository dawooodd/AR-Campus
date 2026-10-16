import { Hono } from 'hono'
import { sign } from 'hono/jwt'
import { prisma } from '../lib/prisma.js'
import bcrypt from 'bcryptjs'

export const login = new Hono()

login.post('/api/login', async (c) => { 
    const { NIM, password } = await c.req.json()

    if (!NIM || !password) {
        return c.json({ message: 'NIM and password are required' }, 400)
    }
    
    const user = await prisma.user.findUnique({ where: { NIM } })

    if(!user || !(await bcrypt.compare(password, user.password))) {
        return c.json({ message: 'Invalid NIM or password' }, 401)
    }

    const token = await sign(
        {
            sub: user.id,
            role: user.role,
            exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24, // 1 hour expiration
        },
        process.env.JWT_SECRET!,
        'HS256'
    )

    return c.json({
        token,
        user: { id: user.id, username: user.username, NIM: user.NIM, role: user.role },
    })
})