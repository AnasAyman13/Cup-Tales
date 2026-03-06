'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getCategories, getProductsByCategory, Category, Product } from '@/utils/api/publicQueries';
import { Tabs, Layout, Typography, Card, Spin, Button, ConfigProvider, Modal, Image } from 'antd';

const { Header, Content } = Layout;
const { Title, Text } = Typography;

export default function CustomerMenu() {
  const [activeTab, setActiveTab] = useState<string>('');
  const [lang, setLang] = useState<'en' | 'ar'>('en'); // Default to English
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);

  // Fetch Categories
  const { data: categories, isLoading: isCategoriesLoading } = useQuery({
    queryKey: ['categories'],
    queryFn: getCategories,
  });

  // Set default tab when categories arrive
  if (categories?.length && !activeTab) {
    setActiveTab(categories[0].id);
  }

  // Fetch Products based on selected category
  const { data: products, isLoading: isProductsLoading } = useQuery({
    queryKey: ['products', activeTab],
    queryFn: () => getProductsByCategory(activeTab),
    enabled: !!activeTab,
  });

  const handleLangToggle = () => {
    setLang(lang === 'en' ? 'ar' : 'en');
  };

  const getDisplayName = (product: Product) => {
    if (lang === 'ar' && product.name_ar) return product.name_ar;
    if (lang === 'en' && product.name_en) return product.name_en;
    return product.name; // Fallback
  };

  return (
    <ConfigProvider direction={lang === 'ar' ? 'rtl' : 'ltr'}>
      <Layout className="min-h-screen bg-[#f6f6f8]">
        <Header className="bg-white px-4 md:px-8 flex justify-between items-center shadow-sm h-16 sticky top-0 z-10 w-full">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-[#2D3194]/10 flex items-center justify-center">
              <span className="text-[#2D3194] font-bold text-lg">CT</span>
            </div>
            <Title level={4} style={{ margin: 0, color: '#14141e' }}>Cup Tales</Title>
          </div>
          <Button onClick={handleLangToggle} type="default" shape="round">
            {lang === 'en' ? 'العربية' : 'English'}
          </Button>
        </Header>

        <Content className="max-w-5xl mx-auto w-full p-4 md:p-8">
          {isCategoriesLoading ? (
            <div className="flex justify-center p-12"><Spin size="large" /></div>
          ) : (
            <Tabs
              activeKey={activeTab}
              onChange={setActiveTab}
              items={categories?.map((cat: Category) => ({
                key: cat.id,
                label: cat.name,
              })) || []}
              className="mt-4"
              size="large"
            />
          )}

          <div className="mt-8">
            {isProductsLoading ? (
              <div className="flex justify-center p-12"><Spin /></div>
            ) : products?.length === 0 ? (
              <div className="text-center text-gray-500 py-12">No products found in this category.</div>
            ) : (
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6">
                {products?.map((prod: Product) => (
                  <Card
                    key={prod.id}
                    hoverable
                    onClick={() => setSelectedProduct(prod)}
                    cover={
                      <div className="h-48 bg-gray-100 overflow-hidden relative">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          alt={getDisplayName(prod)}
                          src={prod.image_url || '/placeholder.png'}
                          className="w-full h-full object-cover transition-transform duration-300 hover:scale-105"
                          loading="lazy"
                          onError={(e) => {
                            (e.target as HTMLImageElement).src = 'https://placehold.co/400x300?text=No+Image';
                          }}
                        />
                      </div>
                    }
                    className="overflow-hidden border-none shadow-sm h-full flex flex-col"
                    bodyStyle={{ padding: '16px', flex: 1, display: 'flex', flexDirection: 'column' }}
                  >
                    <div className="font-semibold text-lg line-clamp-2 mb-2 flex-1">
                      {getDisplayName(prod)}
                    </div>
                    <div className="flex flex-col gap-1 text-gray-600 mt-auto">
                      {prod.price_s !== null && <div><Text strong>S: </Text>{prod.price_s}</div>}
                      {prod.price_m !== null && <div><Text strong>M: </Text>{prod.price_m}</div>}
                      {prod.price_l !== null && <div><Text strong>L: </Text>{prod.price_l}</div>}
                      {/* Fallback if all sizes are suddenly null */}
                      {prod.price_s === null && prod.price_m === null && prod.price_l === null && (
                        <div className="text-gray-400 italic">Price unavailable</div>
                      )}
                    </div>
                  </Card>
                ))}
              </div>
            )}
          </div>
        </Content>

        {/* Product Detail Modal */}
        <Modal
          title={null}
          open={!!selectedProduct}
          onCancel={() => setSelectedProduct(null)}
          footer={null}
          centered
          width={400}
        >
          {selectedProduct && (
            <div className="flex flex-col items-center">
              <Image
                src={selectedProduct.image_url || '/placeholder.png'}
                alt={getDisplayName(selectedProduct)}
                className="rounded-lg object-cover w-full max-h-64"
                fallback="https://placehold.co/400x300?text=No+Image"
              />
              <Title level={4} className="mt-4 mb-1 text-center">{getDisplayName(selectedProduct)}</Title>

              {/* Show alternate names if they exist for curiosity/completeness */}
              <div className="text-gray-400 text-sm mb-4">
                {lang === 'ar' && selectedProduct.name_en ? `(${selectedProduct.name_en})` : ''}
                {lang === 'en' && selectedProduct.name_ar ? `(${selectedProduct.name_ar})` : ''}
              </div>

              <div className="w-full bg-gray-50 p-4 rounded-lg flex flex-col gap-2">
                <div className="font-bold text-gray-500 mb-1">Pricing Options:</div>
                {selectedProduct.price_s !== null && (
                  <div className="flex justify-between items-center border-b pb-2">
                    <Text>Small Size</Text>
                    <Text strong className="text-[#2D3194]">{selectedProduct.price_s}</Text>
                  </div>
                )}
                {selectedProduct.price_m !== null && (
                  <div className="flex justify-between items-center border-b pb-2">
                    <Text>Medium Size</Text>
                    <Text strong className="text-[#2D3194]">{selectedProduct.price_m}</Text>
                  </div>
                )}
                {selectedProduct.price_l !== null && (
                  <div className="flex justify-between items-center">
                    <Text>Large Size</Text>
                    <Text strong className="text-[#2D3194]">{selectedProduct.price_l}</Text>
                  </div>
                )}
                {selectedProduct.price_s === null && selectedProduct.price_m === null && selectedProduct.price_l === null && (
                  <div className="text-center italic text-gray-400 py-2">No pricing available</div>
                )}
              </div>
            </div>
          )}
        </Modal>

      </Layout>
    </ConfigProvider>
  );
}
