//
//  recharge.h
//  ElimGame
//
//  Created by Yan on 16/8/29.
//
//

#ifndef recharge_h
#define recharge_h

#import <StoreKit/StoreKit.h>

typedef void (* BuyFuncCallback)(const char *, const char *, const char *);

typedef void (* LocalFinishCallBack)(const char *, int);

typedef void (* openRunOnceCallBack)();

//代理
@interface recharge : NSObject <SKPaymentTransactionObserver,SKProductsRequestDelegate >

{
    NSString *m_productid;
    NSString *m_orderid;
    BOOL m_isobserver;
    
//    用于控制是否检测检测订单检测
    BOOL m_isopenorderstatuscheck;
//    购买商品的回调, 第一个参数是商品id, 第二个参数是订单id, 第三个参数是凭证
//    用于商品在apple交易完成返回后,向服务器发送订单生效请求的回调
    BuyFuncCallback m_buycb;
    
//    参数为订单号
//    服务器下发订单成功后,客户端再次向服务器发送订单成功的回调, 用于服务器接收到消息后把服务器中订单状态置为完成的状态
    LocalFinishCallBack m_localfinished;
    
//    开启runonce回调
    openRunOnceCallBack m_openrunonce;
    
//    用于保存完成,但未生效的订单信息
    NSMutableDictionary *m_transactions;
}

//初始化订单完成数组
-(void) inittransactions;

//销毁订单数组
-(void) destroytransactions;

//销毁字符串
-(void) destroystr;

//增加已支付,为完成交易的订单
-(void) addtransaction: (SKPaymentTransaction *)transaction receipt: (NSString *)receiptstr;

//初始化, 用于监听注册
-(void) addobserver;

//移除监听
-(void) removeobserver;

//心跳
-(void) runOnce: (float ) dt;

//向服务器发送本地订单成功的请求
-(void) senderservertransaction;

//从transaction队列中删除已完成的transaction
-(void) clearlocaltransaction;

//注册购买成功回调
-(void) registercb: (BuyFuncCallback) buycallback localfinished: (LocalFinishCallBack) localfinishedcb openrunonce: (openRunOnceCallBack) openrunoncecb;

//请求更新数据
-(void) requestProUpgradeProductData;

//请求订单
-(void)RequestProductData: (NSString *) type;

//是否可以内购
-(void)buy:(NSString *)type order:(NSString *)orderid;

//加密apple返回的凭证
- (NSString *)encode:(const uint8_t *)input length:(NSInteger)length;

//用于显示alerView
-(void)showalerview: (NSString *)title message:(NSString *)msg cancle:(NSString *)canclestr;

//付款队列
-(void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;

-(void) PurchasedTransaction: (SKPaymentTransaction *)transaction;

-(void) paymentQueueRestoreCompletedTransactionsFinished: (SKPaymentTransaction *)transaction;

-(void) paymentQueue:(SKPaymentQueue *) paymentQueue restoreCompletedTransactionsFailedWithError:(NSError *)error;

//记录订单信息
-(void) recordTransaction: (SKPaymentTransaction *)transaction;

// 完成交易 用于客户端本地向itunes请求后收到反馈后, 用于处理交易结果
-(void) finished: (SKPaymentTransaction *)transaction;

//服务器校验交易完毕
-(void) serverfinished: (const char *) orderid;

//服务器校验失败,修改订单状态
-(void) serverfailed:(const char *)orderid;


@end

#endif /* recharge_h */
