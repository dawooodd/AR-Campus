import { jwt } from 'hono/jwt'
import { createMiddleware } from 'hono/factory'

type AuthEnv = {
  Variables: {
    jwtPayload: {
      sub: string
      role: 'MAHASISWA' | 'ADMIN'
      exp: number
    }
  }
}

export const requireAuth = jwt({
  secret: process.env.JWT_SECRET!,
  alg: 'HS256',
})

export const requireRole = (role: 'MAHASISWA' | 'ADMIN') =>
  createMiddleware<AuthEnv>(async (c, next) => {
    if (c.get('jwtPayload').role !== role) {
      return c.json({ message: 'Akses ditolak' }, 403)
    }
    await next()
  })