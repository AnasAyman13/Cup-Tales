'use client';

import { useState } from 'react';
import { Upload, Button, message, Table, Card, Typography, Alert } from 'antd';
import { UploadOutlined, DatabaseOutlined } from '@ant-design/icons';
import Papa from 'papaparse';
import { useQuery } from '@tanstack/react-query';
import { getCategories } from '@/utils/api/publicQueries';

const { Title, Text } = Typography;

interface CsvRow {
    _index: number;
    category_id: string | null;
    name: string;
    name_en: string | null;
    name_ar: string | null;
    price_s: number | null;
    price_m: number | null;
    price_l: number | null;
    image_url: string;
    is_active: boolean;
    _isValid: boolean;
}

export default function BulkImport() {
    const [dataPreview, setDataPreview] = useState<CsvRow[]>([]);
    const [loading, setLoading] = useState(false);
    const [results, setResults] = useState<{ success: number; failed: number } | null>(null);

    const { data: categories } = useQuery({ queryKey: ['admin-categories'], queryFn: getCategories });

    const handleFileUpload = (file: File) => {
        Papa.parse(file, {
            header: true,
            skipEmptyLines: true,
            complete: (parsed) => {
                // Map and validate rows
                const mappedRows: CsvRow[] = parsed.data.map((row: unknown, index: number) => {
                    const r = row as Record<string, string>;
                    // Normalize prices
                    const s = r.price_s ? parseFloat(r.price_s) : null;
                    const m = r.price_m ? parseFloat(r.price_m) : null;
                    const l = r.price_l ? parseFloat(r.price_l) : null;

                    // Fill required name
                    const nameEn = r.name_en?.trim();
                    const nameAr = r.name_ar?.trim();
                    const primaryName = nameEn || nameAr || '';

                    return {
                        _index: index + 1, // for table rendering only
                        category_id: r.category_id?.trim() || null,
                        name: primaryName,
                        name_en: nameEn || null,
                        name_ar: nameAr || null,
                        price_s: s,
                        price_m: m,
                        price_l: l,
                        image_url: r.image_url?.trim() || '',
                        is_active: true,
                        _isValid: !!primaryName && !!r.category_id, // Mark invalid if missing name OR category
                    };
                });

                setDataPreview(mappedRows);
                message.success(`Parsed ${mappedRows.length} rows`);
            },
            error: (error: Error) => {
                message.error(`Failed to parse CSV: ${error.message}`);
            }
        });
        return false; // Prevent automatic upload action
    };

    const executeImport = async () => {
        const validRows = dataPreview.filter(r => r._isValid);
        if (validRows.length === 0) {
            return message.warning('No valid rows to import.');
        }

        setLoading(true);

        // Strip out our frontend helper properties
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const payload = validRows.map(({ _index, _isValid, ...rest }) => rest);

        try {
            const response = await fetch('/api/admin/import', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ rows: payload }),
            });

            const resData = await response.json();

            if (!response.ok) throw new Error(resData.error || 'Server error');

            setResults({
                success: resData.count,
                failed: dataPreview.length - validRows.length,
            });
            message.success('Import completed successfully!');
        } catch (error: Error | unknown) {
            if (error instanceof Error) {
                message.error(`Import failed: ${error.message}`);
            } else {
                message.error('Import failed: unknown error');
            }
        } finally {
            setLoading(false);
        }
    };

    const columns = [
        { title: 'Row', dataIndex: '_index', width: 60 },
        {
            title: 'Valid',
            dataIndex: '_isValid',
            render: (isValid: boolean) => (
                <span className={isValid ? "text-green-500 font-bold" : "text-red-500 font-bold"}>
                    {isValid ? 'Y' : 'N'}
                </span>
            )
        },
        { title: 'Primary Name', dataIndex: 'name' },
        { title: 'EN', dataIndex: 'name_en' },
        { title: 'AR', dataIndex: 'name_ar' },
        {
            title: 'Category',
            dataIndex: 'category_id',
            render: (id: string) => categories?.find(c => c.id === id)?.name || <span className="text-red-500">Missing/Unknown</span>
        },
        { title: 'S', dataIndex: 'price_s' },
        { title: 'M', dataIndex: 'price_m' },
        { title: 'L', dataIndex: 'price_l' },
    ];

    return (
        <div className="max-w-5xl">
            <Title level={3}>Bulk Import Products</Title>

            {results && (
                <Alert
                    message="Import Complete"
                    description={`Successfully imported/updated ${results.success} products. Skipped ${results.failed} invalid rows.`}
                    type="success"
                    showIcon
                    className="mb-6"
                    action={
                        <Button size="small" onClick={() => { setResults(null); setDataPreview([]); }}>Start New Import</Button>
                    }
                />
            )}

            <Card className="mb-6 shadow-sm border-none">
                <Typography.Paragraph className="text-gray-600">
                    Upload a CSV file with the following headers:
                    <Text code>category_id</Text>, <Text code>name_en</Text>, <Text code>name_ar</Text>, <Text code>price_s</Text>, <Text code>price_m</Text>, <Text code>price_l</Text>, <Text code>image_url</Text>.
                    <br />
                    If <Text code>name_en</Text> or <Text code>name_ar</Text> exists, <Text code>name</Text> will be automatically populated. Rows missing both names or <Text code>category_id</Text> will be marked as invalid.
                </Typography.Paragraph>

                <Upload
                    accept=".csv"
                    beforeUpload={handleFileUpload}
                    showUploadList={false}
                >
                    <Button icon={<UploadOutlined />} size="large">Select CSV File</Button>
                </Upload>
            </Card>

            {dataPreview.length > 0 && !results && (
                <div className="space-y-4">
                    <div className="flex justify-between items-center">
                        <Text strong>{dataPreview.length} rows loaded. {dataPreview.filter(r => !r._isValid).length} invalid.</Text>
                        <Button
                            type="primary"
                            className="bg-[#2D3194]"
                            icon={<DatabaseOutlined />}
                            onClick={executeImport}
                            loading={loading}
                            disabled={dataPreview.filter(r => r._isValid).length === 0}
                        >
                            Execute Import to Database
                        </Button>
                    </div>
                    <Table<CsvRow>
                        dataSource={dataPreview}
                        columns={columns}
                        rowKey="_index"
                        size="small"
                        pagination={{ pageSize: 15 }}
                        scroll={{ x: 'max-content' }}
                        rowClassName={(record) => !record._isValid ? 'bg-red-50' : ''}
                    />
                </div>
            )}
        </div>
    );
}
