import React from 'react';
import { AntdRegistry } from '@ant-design/nextjs-registry';
import { ConfigProvider } from 'antd';

export function AntdProvider({ children }: { children: React.ReactNode }) {
    return (
        <AntdRegistry>
            <ConfigProvider theme={{
                token: {
                    colorPrimary: '#2D3194',
                }
            }}>
                {children}
            </ConfigProvider>
        </AntdRegistry>
    );
}
