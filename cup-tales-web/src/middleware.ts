import { NextResponse, type NextRequest } from 'next/server'
import { createServerClient } from '@supabase/ssr'

export async function middleware(request: NextRequest) {
    let supabaseResponse = NextResponse.next({
        request,
    })

    // Create an unmodified supabase client specifically for middleware checking
    const supabase = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookies: {
                getAll() {
                    return request.cookies.getAll()
                },
                setAll(cookiesToSet) {
                    cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
                    supabaseResponse = NextResponse.next({
                        request,
                    })
                    cookiesToSet.forEach(({ name, value, options }) =>
                        supabaseResponse.cookies.set(name, value, options)
                    )
                },
            },
        }
    )

    // Verify Auth Session 
    const { data: { user } } = await supabase.auth.getUser()

    const url = request.nextUrl.clone()
    const isAdminRoute = url.pathname.startsWith('/admin')
    const isLoginRoute = url.pathname === '/admin/login'

    if (isAdminRoute && !isLoginRoute && !user) {
        // If attempting to access an admin route while not logged in, boot to login
        url.pathname = '/admin/login'
        return NextResponse.redirect(url)
    }

    if (isLoginRoute && user) {
        // If logged in, don't let them hit the login page again
        url.pathname = '/admin/products'
        return NextResponse.redirect(url)
    }

    return supabaseResponse
}

export const config = {
    matcher: [
        '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
    ],
}
