import { Hono } from 'hono'

export const logout = new Hono()

logout.get('/api/logout', async (c) => {
    try {
        // const prisma = c.get('prisma')
        return c.json({
            success: true,
            message: 'Berhasil keluar'
        }, 200)
    } catch (error) {
        console.error('Error during logout:', error)
        return c.json({
            success: false,
            message: 'Terjadi kesalahan saat keluar',
            error: error instanceof Error ? error.message : 'Unknown error'
        }, 500)
    }
})