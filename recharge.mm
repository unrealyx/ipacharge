#import "recharge.h"
@interface recharge ()

@end

//服务器处理状态key
#define SERVERHANDLE @"SERVERHANDLE"

// 定义服务器处理订单的三种状态value,分别为未处理, 处理中, 已处理, 清理状态
#define UNHANDLE @"UNHANDLE"
#define HANDLING @"HANDLING"
#define FINISHED @"FINISHED"
#define CLEAR @"CLEAR"

//凭证key
#define RECEIPT @"RECEIPT"

//交易单
#define TRANSACTION @"TRANSACTION"

@implementation recharge


//初始化订单完成数组
-(void) inittransactions
{
    if(!m_transactions)
    {
        m_transactions = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
}

//销毁订单数组
-(void) destroytransactions
{
    if(m_transactions)
    {
        [m_transactions release];
        m_transactions = nullptr;
    }
}

//销毁字符串
-(void) destroystr
{
    if(m_orderid)
    {
        [m_orderid release];
        m_orderid = nullptr;
    }
    
    if(m_productid)
    {
        [m_productid release];
        m_productid = nullptr;
    }
}

// 记得生成充值对象时手动调用init函数, 用于注册监听
-(void) addobserver
{
    m_isobserver = YES;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

-(void) removeobserver
{
    m_isobserver = NO;
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

//增加已支付,为完成交易的订单
-(void) addtransaction: (SKPaymentTransaction *)transaction receipt: (NSString *)receiptstr
{
//    如果transaction dictionnary 没有初始化,则初始化
    if(!m_transactions) [self inittransactions];
    
//    把transaction相关数据保存到一个字典中, 包括transaction数据, 处理状态, apple给的处理凭证
    NSMutableDictionary *transmap = [NSMutableDictionary dictionaryWithObjectsAndKeys:UNHANDLE, SERVERHANDLE, transaction, TRANSACTION, receiptstr, RECEIPT, nil];
    NSString *orderid = transaction.payment.applicationUsername;
    if(orderid)
//    把transmap数据塞到dictionary中
        [m_transactions setValue:transmap forKey:orderid];
    else
        [self finished:transaction];
}

//注册购买成功回调
-(void) registercb: (BuyFuncCallback) buycallback localfinished: (LocalFinishCallBack) localfinishedcb openrunonce: (openRunOnceCallBack) openrunoncecb;
{
    m_buycb = buycallback;
    m_localfinished = localfinishedcb;
    m_openrunonce = openrunoncecb;
}

//心跳
-(void) runOnce: (float ) dt
{
    [self clearlocaltransaction];
    [self senderservertransaction];
}

//向服务器发送本地订单成功的请求
-(void) senderservertransaction
{
    if(!m_buycb) return;
//    遍历transaction, 选择unhandle的向服务器发送
    for(id orderid in m_transactions) {
        NSMutableDictionary *transmap = [m_transactions objectForKey:orderid];
        NSString *handle = [transmap objectForKey:SERVERHANDLE];
        if(transmap && [handle isEqualToString:UNHANDLE])
        {
//            拿到transaction数据
            SKPaymentTransaction * transaction = [transmap objectForKey:TRANSACTION];
//            拿到凭证
            NSString *receipt = [transmap objectForKey:RECEIPT];
            
//            把transaction状态置为handling
            [[m_transactions objectForKey:orderid] setValue:HANDLING forKey:SERVERHANDLE];
            
            NSString *productid = transaction.payment.productIdentifier;
            NSString *orderid = transaction.payment.applicationUsername;
//            向服务器发送验证成功请求
            m_buycb([productid UTF8String], [orderid UTF8String], [receipt UTF8String]);
        }
    }
}

//从transaction队列中删除已完成的transaction
-(void) clearlocaltransaction
{
    NSMutableArray *tmparray = [[NSMutableArray alloc] init];
    for (id orderid in m_transactions)
    {
        NSDictionary *transmap = [m_transactions objectForKey:orderid];
        NSString *handle = [transmap objectForKey:SERVERHANDLE];

        if(transmap && [handle isEqualToString:FINISHED])
        {
//            拿到transaction数据
            SKPaymentTransaction * transaction = [transmap objectForKey:TRANSACTION];
            
//            将transaction移除queue队列
            [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
            
//            记录到array中, for循环完成后删除
            [tmparray addObject:orderid];
        }
    }
    [m_transactions removeObjectsForKeys:tmparray];
}

//服务器校验交易完毕
//用于app服务器发送给客户端消息后修改transaction状态
-(void) serverfinished: (const char *) orderid
{
    NSDictionary *transmap = [m_transactions objectForKey: [NSString stringWithUTF8String: orderid]];
    if(!transmap) return;
    
    SKPaymentTransaction * transaction = [transmap objectForKey:TRANSACTION];
    NSString *handlestate = [transmap objectForKey:SERVERHANDLE];
    if(transaction && [handlestate isEqualToString:HANDLING])
        [self finished:transaction];
}


//服务器校验失败,修改订单状态, 恢复为未处理状态
-(void) serverfailed:(const char *)orderid
{
    NSDictionary *transmap = [m_transactions objectForKey: [NSString stringWithUTF8String: orderid]];
    if(!transmap) return;
    
    SKPaymentTransaction * transaction = [transmap objectForKey:TRANSACTION];
    NSString *handlestate = [transmap objectForKey:SERVERHANDLE];
    if(transaction && [handlestate isEqualToString:HANDLING])
        [[m_transactions objectForKey:[NSString stringWithUTF8String: orderid]] setValue:UNHANDLE forKey:SERVERHANDLE];
}

-(void)buy:(NSString *)productid order:(NSString *)orderid;
{
    if ([SKPaymentQueue canMakePayments])
    {
        //    判断有没有打开监听, 如果没有打开,则打开监听
        if(!m_isobserver) [self addobserver];
        
        // 销毁字符串,防止内存泄露
        [self destroystr];
        
        m_productid = [[NSString alloc] initWithFormat:@"%@", productid];
        
        m_orderid = [[NSString alloc] initWithFormat:@"%@", orderid];
        
        NSLog(@"orderid : %@,  productid : %@", m_orderid, m_productid);
//      如果可以进行内购,则直接调用支付接口
        [self RequestProductData: productid];
    }
    else
    {
        if(m_localfinished) m_localfinished([orderid UTF8String], SKPaymentTransactionStateFailed);
        
//      如果内购开关没开,则弹出提示信息
        [self showalerview:@"提示" message:@"程序内付费购买未开启" cancle:@"关闭"];
    }
}

-(void)showalerview: (NSString *)title message:(NSString *)msg cancle:(NSString *)canclestr
{
    UIAlertView *alerView =  [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:nil cancelButtonTitle:NSLocalizedString(canclestr,nil) otherButtonTitles:nil];
    
    [alerView show];
}

//请求商品列表
-(void)RequestProductData:(NSString *) productid
{
    NSArray *product = [[NSArray alloc] initWithObjects:productid, nil];
    NSSet *nsset = [NSSet setWithArray:product];
    SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers: nsset];
    request.delegate=self;
    [request start];
}

//<SKProductsRequestDelegate> 请求协议
//收到的产品反馈信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    
    NSArray *myProduct = response.products;
//  没有商品
    if(0 == [myProduct count]) return;

//  用于ui显示
    SKProduct *p = nil;
    for(SKProduct *product in myProduct)
    {
        NSLog(@"product info");
        NSLog(@"SKProduct 描述信息%@", [product description]);
        NSLog(@"产品标题 %@" , product.localizedTitle);
        NSLog(@"产品描述信息: %@" , product.localizedDescription);
        NSLog(@"价格: %@" , product.price);
        NSLog(@"Product id: %@" , product.productIdentifier);
        if([product.productIdentifier isEqualToString:m_productid])
        {
            p = product;
            break;
        }
    }
    if(p)
    {
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:p];
        NSLog(@"m_orderid : %@", m_orderid);
        payment.applicationUsername = m_orderid;
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}


//弹出错误信息
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"error msg: %@", [error localizedDescription]);
}


//----监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions//交易结果
{
    bool hassuccessorder = false;
    NSLog(@"-----paymentQueue--------");
    for (SKPaymentTransaction *transaction in transactions)
    {
        //向上层传送订单状态
        if(transaction.payment.applicationUsername && m_localfinished)
            m_localfinished([transaction.payment.applicationUsername UTF8String], transaction.transactionState);
        
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                //交易完成
                [self recordTransaction:transaction];
                hassuccessorder = true;
                break;
            case SKPaymentTransactionStatePurchasing:
                break;
            case SKPaymentTransactionStateRestored:
                break;
            case SKPaymentTransactionStateFailed:
            // 其他状态直接删除订单
            default:
                [self finished:transaction];
                break;
        }
    }
//    开启心跳查询订单status
    if(m_openrunonce && hassuccessorder) m_openrunonce();
}

- (NSString *)encode:(const uint8_t *)input length:(NSInteger)length
{
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData *data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t *output = (uint8_t *)data.mutableBytes;
    
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

//交易成功记录数据
- (void) recordTransaction: (SKPaymentTransaction *)transaction
{
//    得到商品号
    NSString *product = transaction.payment.productIdentifier;
    
//    得到凭证
    NSString* receiptstr = [self encode:(uint8_t *)transaction.transactionReceipt.bytes
                                       length:transaction.transactionReceipt.length];

    if ([product length] > 0)
    {
//        把transaction加入到队列中
        [self addtransaction:transaction receipt:receiptstr];
    }
}

-(void) paymentQueueRestoreCompletedTransactionsFinished: (SKPaymentTransaction *)transaction
{
    
}


// paymentQueue
-(void) paymentQueue:(SKPaymentQueue *) paymentQueue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    
}

// 完成交易 用于客户端本地向itunes请求后收到反馈后, 用于处理交易结果
-(void) finished: (SKPaymentTransaction *)transaction
{
    NSString *orderid = transaction.payment.applicationUsername;
    
    // 如果订单号为空或者在map中未找到,则直接从内购队列移除
    if(!orderid || ![m_transactions objectForKey:orderid])
    {
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        return;
    }

//    修改订单处理状态
    [[m_transactions objectForKey:orderid] setValue:FINISHED forKey:SERVERHANDLE];
    
}


// 销毁NSArray数组
-(void) dealloc
{
    [super dealloc];
    [self destroytransactions];
    [self destroystr];
}


@end
