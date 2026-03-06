import { createClient } from '../supabase/client';
import { Product } from './publicQueries';

export async function getAdminProducts(categoryId?: string, search?: string) {
    const supabase = createClient();
    let query = supabase.from('products').select('*');

    if (categoryId) {
        query = query.eq('category_id', categoryId);
    }
    if (search) {
        query = query.or(`name.ilike.%${search}%,name_en.ilike.%${search}%,name_ar.ilike.%${search}%`);
    }

    // We want to see all products, even inactive, so no is_active filter here
    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return data as Product[];
}

export async function updateProduct(id: string, updates: Partial<Product>) {
    const supabase = createClient();
    const { data, error } = await supabase
        .from('products')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    if (error) throw new Error(error.message);
    return data;
}

export async function deleteProduct(id: string) {
    const supabase = createClient();
    const { error } = await supabase
        .from('products')
        .delete()
        .eq('id', id);

    if (error) throw new Error(error.message);
    return true;
}

export async function addProduct(product: Omit<Product, 'id' | 'created_at'>) {
    const supabase = createClient();
    const { data, error } = await supabase
        .from('products')
        .insert([product])
        .select()
        .single();

    if (error) throw new Error(error.message);
    return data;
}
