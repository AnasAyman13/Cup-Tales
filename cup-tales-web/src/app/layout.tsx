import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { AntdProvider } from '@/components/providers/AntdProvider'
import { ReactQueryProvider } from '@/components/providers/ReactQueryProvider'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Cup Tales | Menu & Order',
  description: 'Welcome to Cup Tales café. Browse our latest menu.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <ReactQueryProvider>
          <AntdProvider>
            {children}
          </AntdProvider>
        </ReactQueryProvider>
      </body>
    </html>
  )
}
