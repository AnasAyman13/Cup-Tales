'use client';

import { useState } from 'react';
import { createClient } from '@/utils/supabase/client';
import { useRouter } from 'next/navigation';
import { Button, Input, Form, message, Card, Typography } from 'antd';
import { LockOutlined, UserOutlined } from '@ant-design/icons';

const { Title } = Typography;

interface LoginValues {
    email?: string;
    password?: string;
}

export default function AdminLogin() {
    const [loading, setLoading] = useState(false);
    const router = useRouter();
    const supabase = createClient();

    const handleLogin = async (values: LoginValues) => {
        setLoading(true);
        const { error } = await supabase.auth.signInWithPassword({
            email: values.email || '',
            password: values.password || '',
        });

        setLoading(false);

        if (error) {
            message.error(error.message);
        } else {
            message.success('Logged in successfully');
            router.push('/admin/products');
            router.refresh();
        }
    };

    return (
        <div className="min-h-screen bg-gray-100 flex items-center justify-center p-4">
            <Card className="w-full max-w-md shadow-xl border-none">
                <div className="text-center mb-8">
                    <div className="w-16 h-16 bg-[#2D3194] text-white rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-4">
                        CT
                    </div>
                    <Title level={3} style={{ margin: 0 }}>Cup Tales Admin</Title>
                    <span className="text-gray-500">Sign in to manage the application</span>
                </div>

                <Form
                    name="admin_login"
                    layout="vertical"
                    onFinish={handleLogin}
                    autoComplete="off"
                >
                    <Form.Item
                        name="email"
                        rules={[
                            { required: true, message: 'Please input your email!' },
                            { type: 'email', message: 'Enter a valid email' }
                        ]}
                    >
                        <Input
                            prefix={<UserOutlined className="text-gray-400" />}
                            placeholder="Admin Email"
                            size="large"
                        />
                    </Form.Item>

                    <Form.Item
                        name="password"
                        rules={[{ required: true, message: 'Please input your password!' }]}
                    >
                        <Input.Password
                            prefix={<LockOutlined className="text-gray-400" />}
                            placeholder="Password"
                            size="large"
                        />
                    </Form.Item>

                    <Form.Item>
                        <Button
                            type="primary"
                            htmlType="submit"
                            className="w-full bg-[#2D3194]"
                            size="large"
                            loading={loading}
                        >
                            Log in
                        </Button>
                    </Form.Item>
                </Form>
            </Card>
        </div>
    );
}
