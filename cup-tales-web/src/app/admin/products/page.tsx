'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getAdminProducts, updateProduct, deleteProduct, addProduct } from '@/utils/api/adminProductQueries';
import { getCategories, Category, Product } from '@/utils/api/publicQueries';
import { Table, Button, Modal, Form, Input, InputNumber, Select, Switch, message, Popconfirm, Typography, Tooltip, Tag } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, ExclamationCircleOutlined } from '@ant-design/icons';
import debounce from 'lodash/debounce';

const { Title } = Typography;
const { Option } = Select;

export default function AdminProducts() {
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [editingProduct, setEditingProduct] = useState<Product | null>(null);
    const [selectedCategory, setSelectedCategory] = useState<string | undefined>(undefined);
    const [searchText, setSearchText] = useState<string>('');

    const [form] = Form.useForm();
    const queryClient = useQueryClient();

    const { data: categories } = useQuery({ queryKey: ['admin-categories'], queryFn: getCategories });

    const { data: products, isLoading: isProductsLoading } = useQuery({
        queryKey: ['admin-products', selectedCategory, searchText],
        queryFn: () => getAdminProducts(selectedCategory, searchText),
    });

    const mutationUpdate = useMutation({
        mutationFn: (values: { id: string } & Partial<Product>) => updateProduct(values.id, values),
        onSuccess: () => {
            message.success('Product updated');
            queryClient.invalidateQueries({ queryKey: ['admin-products'] });
            setIsModalVisible(false);
        },
        onError: (err: Error) => message.error(err.message),
    });

    const mutationAdd = useMutation({
        mutationFn: (values: Omit<Product, 'id' | 'created_at'>) => addProduct(values),
        onSuccess: () => {
            message.success('Product added');
            queryClient.invalidateQueries({ queryKey: ['admin-products'] });
            setIsModalVisible(false);
        },
        onError: (err: Error) => message.error(err.message),
    });

    const mutationDelete = useMutation({
        mutationFn: deleteProduct,
        onSuccess: () => {
            message.success('Product deleted');
            queryClient.invalidateQueries({ queryKey: ['admin-products'] });
        },
        onError: (err: Error) => message.error(err.message),
    });

    const handleSearch = debounce((value: string) => {
        setSearchText(value);
    }, 300);

    const handleEdit = (product: Product) => {
        setEditingProduct(product);
        form.setFieldsValue(product);
        setIsModalVisible(true);
    };

    const handleCreate = () => {
        setEditingProduct(null);
        form.resetFields();
        form.setFieldsValue({ is_active: true });
        setIsModalVisible(true);
    };

    const handleSubmit = (values: Partial<Product>) => {
        if (editingProduct) {
            mutationUpdate.mutate({ id: editingProduct.id, ...values });
        } else {
            mutationAdd.mutate(values as Omit<Product, 'id' | 'created_at'>);
        }
    };

    // OCR Fix Helper
    const renderPriceWithOCRCheck = (price: number | null, record: Product, priceField: string) => {
        if (price === null) return '-';

        // Suggestion logic (e.g., 610 -> 110, 5053 -> 53)
        let hasWarning = false;
        let suggestedPrice = price;

        if (price > 500) {
            hasWarning = true;
            const priceStr = price.toString();
            if (priceStr.startsWith('6') && priceStr.length === 3) suggestedPrice = parseInt('1' + priceStr.substring(1)); // 610 -> 110
            if (priceStr.startsWith('50') && priceStr.length >= 4) suggestedPrice = parseInt(priceStr.substring(2)); // 5053 -> 53
        }

        if (!hasWarning) return price;

        return (
            <Tooltip title={`Suspicious OCR price. Click to fix to ${suggestedPrice}?`}>
                <Tag color="red" className="cursor-pointer" onClick={() => {
                    Modal.confirm({
                        title: 'Fix OCR Price Mistake',
                        content: `Change price from ${price} to ${suggestedPrice}?`,
                        onOk: () => {
                            mutationUpdate.mutate({ id: record.id, [priceField]: suggestedPrice } as { id: string } & Partial<Product>);
                        }
                    });
                }}>
                    {price} <ExclamationCircleOutlined />
                </Tag>
            </Tooltip>
        );
    };

    const columns = [
        {
            title: 'Image',
            dataIndex: 'image_url',
            key: 'image_url',
            render: (url: string) => (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={url || '/placeholder.png'} alt="product" className="w-12 h-12 object-cover rounded" onError={(e) => { (e.target as HTMLImageElement).src = 'https://placehold.co/48?text=No' }} />
            ),
        },
        {
            title: 'Primary Name',
            dataIndex: 'name',
            key: 'name',
            render: (text: string, record: Product) => (
                <div>
                    <div className="font-semibold">{text}</div>
                    <div className="text-xs text-gray-500">EN: {record.name_en || '-'} | AR: {record.name_ar || '-'}</div>
                </div>
            )
        },
        {
            title: 'Category',
            dataIndex: 'category_id',
            key: 'category_id',
            render: (catId: string) => {
                const cat = categories?.find((c: Category) => c.id === catId);
                return cat ? cat.name : catId;
            }
        },
        {
            title: 'Price (S)',
            dataIndex: 'price_s',
            render: (val: number, rec: Product) => renderPriceWithOCRCheck(val, rec, 'price_s')
        },
        {
            title: 'Price (M)',
            dataIndex: 'price_m',
            render: (val: number, rec: Product) => renderPriceWithOCRCheck(val, rec, 'price_m')
        },
        {
            title: 'Price (L)',
            dataIndex: 'price_l',
            render: (val: number, rec: Product) => renderPriceWithOCRCheck(val, rec, 'price_l')
        },
        {
            title: 'Status',
            dataIndex: 'is_active',
            render: (isActive: boolean, record: Product) => (
                <Switch
                    checked={isActive}
                    onChange={(checked: boolean) => mutationUpdate.mutate({ id: record.id, is_active: checked })}
                    loading={mutationUpdate.isPending && mutationUpdate.variables?.id === record.id}
                />
            )
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: Product) => (
                <div className="flex gap-2">
                    <Button type="text" icon={<EditOutlined />} onClick={() => handleEdit(record)} />
                    <Popconfirm title="Delete?" onConfirm={() => mutationDelete.mutate(record.id)}>
                        <Button danger type="text" icon={<DeleteOutlined />} />
                    </Popconfirm>
                </div>
            ),
        },
    ];

    return (
        <div>
            <div className="flex justify-between items-center mb-6">
                <Title level={3} className="!mb-0">Products Management</Title>
                <Button type="primary" icon={<PlusOutlined />} onClick={handleCreate} className="bg-[#2D3194]">
                    Add Product
                </Button>
            </div>

            <div className="bg-white p-4 rounded-lg shadow-sm mb-6 flex gap-4">
                <Input.Search
                    placeholder="Search items..."
                    allowClear
                    onChange={(e: React.ChangeEvent<HTMLInputElement>) => handleSearch(e.target.value)}
                    className="max-w-xs"
                />
                <Select
                    allowClear
                    placeholder="Filter by Category"
                    className="min-w-[200px]"
                    onChange={setSelectedCategory}
                >
                    {categories?.map((cat: Category) => <Option key={cat.id} value={cat.id}>{cat.name}</Option>)}
                </Select>
            </div>

            <Table<Product>
                dataSource={products}
                columns={columns}
                rowKey="id"
                loading={isProductsLoading}
                pagination={{ pageSize: 20 }}
                className="bg-white rounded-lg shadow-sm"
                scroll={{ x: 'max-content' }}
            />

            <Modal
                title={editingProduct ? "Edit Product" : "New Product"}
                open={isModalVisible}
                onCancel={() => setIsModalVisible(false)}
                onOk={() => form.submit()}
                width={600}
                confirmLoading={mutationUpdate.isPending || mutationAdd.isPending}
            >
                <Form form={form} layout="vertical" onFinish={handleSubmit}>
                    <div className="grid grid-cols-2 gap-4">
                        <Form.Item name="name" label="Primary Name (Required)" rules={[{ required: true }]}>
                            <Input />
                        </Form.Item>
                        <Form.Item name="category_id" label="Category" rules={[{ required: true }]}>
                            <Select>
                                {categories?.map((cat: Category) => <Option key={cat.id} value={cat.id}>{cat.name}</Option>)}
                            </Select>
                        </Form.Item>
                        <Form.Item name="name_en" label="Name (English)">
                            <Input />
                        </Form.Item>
                        <Form.Item name="name_ar" label="Name (Arabic)">
                            <Input dir="rtl" />
                        </Form.Item>
                    </div>

                    <div className="grid grid-cols-3 gap-4">
                        <Form.Item name="price_s" label="Price (S)"><InputNumber className="w-full" /></Form.Item>
                        <Form.Item name="price_m" label="Price (M)"><InputNumber className="w-full" /></Form.Item>
                        <Form.Item name="price_l" label="Price (L)"><InputNumber className="w-full" /></Form.Item>
                    </div>

                    <Form.Item name="image_url" label="Image URL">
                        <Input placeholder="https://..." />
                    </Form.Item>

                    <Form.Item name="is_active" valuePropName="checked">
                        <Switch checkedChildren="Active" unCheckedChildren="Inactive" />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
