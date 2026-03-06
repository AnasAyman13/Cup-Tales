export default function AdminLayout({ children }: { children: React.ReactNode }) {
    // We will add the Sidebar here soon and server-side Auth verification
    return (
        <div className="min-h-screen bg-gray-50 flex flex-col md:flex-row">
            {/* Sidebar Placeholder */}
            <aside className="w-full md:w-64 bg-[#2D3194] text-white p-6 hidden md:block">
                <div className="font-bold text-2xl mb-8">Cup Tales Admin</div>
                <nav className="space-y-4">
                    <a href="/admin/products" className="block opacity-80 hover:opacity-100">Products</a>
                    <a href="/admin/categories" className="block opacity-80 hover:opacity-100">Categories</a>
                    <a href="/admin/import" className="block opacity-80 hover:opacity-100">Bulk Import</a>
                </nav>
            </aside>

            {/* Main Content */}
            <main className="flex-1 p-4 md:p-8 overflow-y-auto w-full">
                {children}
            </main>
        </div>
    );
}
