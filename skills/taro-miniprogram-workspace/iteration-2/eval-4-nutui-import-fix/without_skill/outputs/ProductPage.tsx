import { View, Text } from '@tarojs/components'
import { Button, Toast } from '@nutui/nutui-react-taro'
import styles from './index.module.scss'

export default function ProductPage() {
  const handleAddCart = () => {
    Toast.show({ content: '已加入购物车', icon: 'success' })
  }

  return (
    <View className={styles.page}>
      <Text className={styles.title}>商品详情</Text>
      <Button type='primary' onClick={handleAddCart}>加入购物车</Button>
    </View>
  )
}
