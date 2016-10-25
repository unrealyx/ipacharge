//
//  rechargemgr.m
//  ElimGame
//
//  Created by Yan on 16/8/30.
//
//

#import "rechargemgr.h"
#import "recharge.h"

namespace payrecharge {
    rechargemgr* rechargemgr::mgr = nullptr;
    
    rechargemgr::rechargemgr():m_rec(nullptr)
    {
        recharge* trec = [recharge alloc];
        [trec addobserver];
        [trec retain];
        m_rec = (void *)trec;
    }
    
    rechargemgr::~rechargemgr()
    {
        [(recharge*)m_rec removeobserver];
        [(recharge*)m_rec release];
        m_rec = nullptr;
    }
    
    void rechargemgr::buy(const char *product, const char *orderid)
    {
        [(recharge*)m_rec buy: [NSString stringWithUTF8String:product] order:[NSString stringWithUTF8String: orderid]];
    }
    
    
    void rechargemgr::registercb(BuyFuncCallback buycallback, LocalFinishCallBack localfinishedcb, openRunOnceCallBack openrunoncecb)
    {
        [(recharge*)m_rec registercb: buycallback localfinished:localfinishedcb openrunonce:openrunoncecb];
    }
    
    void rechargemgr::removeobserver()
    {
        [(recharge*)m_rec removeobserver];
    }
    
    void rechargemgr::addobserver()
    {
        [(recharge*)m_rec addobserver];
    }
    
    void rechargemgr::runOnce(float dt)
    {
        if(m_rec) [(recharge*)m_rec runOnce:dt];
    }
    
    void rechargemgr::serverfinished(const char *orderid)
    {
        if(m_rec) [(recharge*)m_rec serverfinished:orderid];
    }
    
    void rechargemgr::serverfailed(const char *orderid)
    {
        if(m_rec) [(recharge*)m_rec serverfailed:orderid];
    }
    
    rechargemgr &rechargemgr::getInstance()
    {
        if(!mgr)
        {
            mgr = new rechargemgr();
        }
        return *mgr;
    }
    
    void rechargemgr::destroyInstance()
    {
        if(mgr)
        {
            delete mgr;
            mgr = nullptr;
        }
    }

};

