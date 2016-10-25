#ifndef rechargemgr_h
#define rechargemgr_h

//#include "recharge.h"

namespace payrecharge {
    
    class rechargemgr
    {
    public:
        
        static rechargemgr &getInstance();
        
        static void destroyInstance();
        
        //    开始内购, 如果不能内购,会弹提示框
        void buy(const char *productid, const char *orderid);
        
        //    移除监听,在程序切入后台的时候
        void removeobserver();
        
        //    程序在前台的时候增加监听
        void addobserver();
        
        //    注册内购完成回调, 和服务器二次认证回调, 开启心跳接口
        void registercb(void(*)(const char *, const char *, const char *), void(*)(const char *, int), void(*)());
        
        //服务器校验交易完毕
        void serverfinished(const char *);
        
        //服务器校验失败,修改订单状态
        void serverfailed(const char *orderid);
        
        //    心跳
        void runOnce(float dt);
        
    private:
        
        rechargemgr();
        
        ~rechargemgr();
        
        //    ios内购对象指针, 省去引入rechager头文件,用的时候需要强制转化
        void *m_rec;
        
        //    静态单例对象, app有一个mgr就够用了
        static rechargemgr * mgr;
        
    };
};


#endif
