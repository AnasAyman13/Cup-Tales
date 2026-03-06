import { createClient } from '../supabase/client';

export async function addCategory(name: string, slug?: string) {
    const supabase = createClient();
    const { data, error } = await supabase
        .from('categories')
        .insert([{ name, slug }])
        .select()
        .single();

    if (error) throw new Error(error.message);
    return data;
}

export async function updateCategory(id: string, name: string, slug?: string) {
    const supabase = createClient();
    const { data, error } = await supabase
        .from('categories')
        .update({ name, slug })
        .eq('id', id)
        .select()
        .single();

    if (error) throw new Error(error.message);
    return data;
}

export async function deleteCategory(id: string) {
    const supabase = createClient();
    const { error } = await supabase
        .from('categories')
        .delete()
        .eq('id', id);

    if (error) throw new Error(error.message);
    return true;
}
