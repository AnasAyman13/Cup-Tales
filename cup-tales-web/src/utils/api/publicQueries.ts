import { createClient } from '../supabase/client';

export type Category = {
    id: string;
    name: string;
    slug?: string;
};

export type Product = {
    id: string;
    category_id: string;
    name: string;
    name_en: string | null;
    name_ar: string | null;
    price_s: number | null;
    price_m: number | null;
    price_l: number | null;
    image_url: string;
    is_active: boolean;
    created_at: string;
};

export async function getCategories() {
    const supabase = createClient();
    const { data, error } = await supabase
        .from('categories')
        .select('*')
        .order('name');

    if (error) throw new Error(error.message);
    return data as Category[];
}

export async function getProductsByCategory(categoryId: string) {
    if (!categoryId) return [];

    const supabase = createClient();
    const { data, error } = await supabase
        .from('products')
        .select('*')
        .eq('category_id', categoryId)
        .eq('is_active', true)
        .order('name');

    if (error) throw new Error(error.message);
    return data as Product[];
}
