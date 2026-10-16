import 'dotenv/config'
import { serve } from '@hono/node-server'
import { Hono } from 'hono'
// import { logout } from './auth/logout.js'
import { prisma } from './lib/prisma.js'
import { register } from './auth/register.js'
import { requireAuth, requireRole } from './auth/middleware.js'
import { login } from './auth/login.js'
import { dashboard } from './route/page/dashboard.js'

const app = new Hono()

app.route('/auth', register)
app.route('/auth', login)

app.use('/dashboard/*', requireAuth, requireRole('MAHASISWA'))
app.route('/dashboard', dashboard)


// app.get('/', (c) => {
//   return c.text('Hello Hono!')
// })

const server = serve({
  fetch: app.fetch,
  port: 3000
}, (info) => {
  console.log(`Server is running on http://localhost:${info.port}`)
})

async function shutdown(signal: string) { 
  console.log(`Received ${signal}. Shutting down gracefully...`)
  try {
    await prisma.$disconnect()
  } catch (err) {
    console.error('Error during Prisma disconnect:', err)
  }
  server.close((err) => { 
    if (err) { 
      console.error('Error occurred while shutting down the server:', err)
      process.exit(1)
    }
    console.log('Server has been shut down.')
    process.exit(0)
  })
}

process.on('SIGINT', () => shutdown('SIGINT'))
process.on('SIGTERM', () => shutdown('SIGTERM'))