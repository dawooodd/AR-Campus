import { Hono } from 'hono'
import { prisma } from '../../lib/prisma.js';

type Env = {
    Variables: {
        user: { id: string; role: string }
    }
}

export const dashboard = new Hono<Env>()

dashboard.get('/:id', async (c) => { 
    const Authuser = c.get('user')
    const userId = c.req.param('id')

    if(Authuser.id !== userId && Authuser.role !== 'ADMIN') {
        return c.json({ message: 'Unauthorized' }, 403)
    }

    const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
            id: true,
            NIM: true,
            username: true,
            role: true
        }
    })

    if (!user) {
        return c.json({ message: 'User not found' }, 404)
    }

    return c.json({ message: 'Berhasil mendapatkan data user', user }, 200)
})