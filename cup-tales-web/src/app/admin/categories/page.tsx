'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getCategories, Category } from '@/utils/api/publicQueries';
import { addCategory, updateCategory, deleteCategory } from '@/utils/api/adminCategoryQueries';
import { Table, Button, Modal, Form, Input, message, Popconfirm, Typography } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';

const { Title } = Typography;

export default function AdminCategories() {
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [editingCategory, setEditingCategory] = useState<Category | null>(null);
    const [form] = Form.useForm();
    const queryClient = useQueryClient();

    const { data: categories, isLoading } = useQuery({
        queryKey: ['admin-categories'],
        queryFn: getCategories,
    });

    const mutationAdd = useMutation({
        mutationFn: (values: { name: string; slug?: string }) => addCategory(values.name, values.slug),
        onSuccess: () => {
            message.success('Category added');
            queryClient.invalidateQueries({ queryKey: ['admin-categories'] });
            setIsModalVisible(false);
        },
        onError: (err: Error) => message.error(err.message),
    });

    const mutationUpdate = useMutation({
        mutationFn: (values: { id: string, name: string; slug?: string }) => updateCategory(values.id, values.name, values.slug),
        onSuccess: () => {
            message.success('Category updated');
            queryClient.invalidateQueries({ queryKey: ['admin-categories'] });
            setIsModalVisible(false);
            setEditingCategory(null);
        },
        onError: (err: Error) => message.error(err.message),
    });

    const mutationDelete = useMutation({
        mutationFn: deleteCategory,
        onSuccess: () => {
            message.success('Category deleted');
            queryClient.invalidateQueries({ queryKey: ['admin-categories'] });
        },
        onError: (err: Error) => message.error(err.message),
    });

    const handleEdit = (category: Category) => {
        setEditingCategory(category);
        form.setFieldsValue({
            name: category.name,
            slug: category.slug || '',
        });
        setIsModalVisible(true);
    };

    const handleCreate = () => {
        setEditingCategory(null);
        form.resetFields();
        setIsModalVisible(true);
    };

    const handleSubmit = (values: { name: string; slug?: string }) => {
        if (editingCategory) {
            mutationUpdate.mutate({ id: editingCategory.id, ...values });
        } else {
            mutationAdd.mutate(values);
        }
    };

    const columns = [
        { title: 'Name', dataIndex: 'name', key: 'name' },
        { title: 'Slug', dataIndex: 'slug', key: 'slug' },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: Category) => (
                <div className="flex gap-2">
                    <Button icon={<EditOutlined />} onClick={() => handleEdit(record)} />
                    <Popconfirm
                        title="Delete this category?"
                        onConfirm={() => mutationDelete.mutate(record.id)}
                        okText="Yes"
                        cancelText="No"
                        okButtonProps={{ danger: true }}
                    >
                        <Button danger icon={<DeleteOutlined />} />
                    </Popconfirm>
                </div>
            ),
        },
    ];

    return (
        <div>
            <div className="flex justify-between items-center mb-6">
                <Title level={3} className="!mb-0">Categories</Title>
                <Button
                    type="primary"
                    icon={<PlusOutlined />}
                    onClick={handleCreate}
                    className="bg-[#2D3194]"
                >
                    Add Category
                </Button>
            </div>

            <Table<Category>
                dataSource={categories}
                columns={columns}
                rowKey="id"
                loading={isLoading}
                pagination={{ pageSize: 20 }}
                className="bg-white rounded-lg shadow-sm"
            />

            <Modal
                title={editingCategory ? "Edit Category" : "New Category"}
                open={isModalVisible}
                onCancel={() => {
                    setIsModalVisible(false);
                    form.resetFields();
                }}
                onOk={() => form.submit()}
                confirmLoading={mutationAdd.isPending || mutationUpdate.isPending}
            >
                <Form form={form} layout="vertical" onFinish={handleSubmit}>
                    <Form.Item name="name" label="Category Name" rules={[{ required: true, message: 'Please input the name!' }]}>
                        <Input placeholder="e.g. HOT DRINKS" />
                    </Form.Item>
                    <Form.Item name="slug" label="Slug (Optional)">
                        <Input placeholder="e.g. hot-drinks" />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
