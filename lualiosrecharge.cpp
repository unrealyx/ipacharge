//
//  lualiosrecharge.cpp
//  ElimGame
//
//  Created by Yan on 16/8/31.
//
//
#ifdef __cplusplus
extern "C"{
#endif
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#ifdef __cplusplus
}
#endif

#include "lualiosrecharge.hpp"
#include "cocos2d.h"
#include "../Utility/sr_cocos.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
#include "rechargemgr.h"
#endif

static lua_State *localLuastate = NULL;

static int lualiosrechargeapi_buy(lua_State *L)
{
    if (!L) return 0;
    
    const char *productid = (char *)luaL_checkstring(L, 1);
    
    const char *orderid = (char *)luaL_checkstring(L, 2);
    
    payrecharge::rechargemgr::getInstance().buy(productid, orderid);
    
    return 1;
}

static int lualiosrechargeapi_removeobserver(lua_State *L)
{
    if (!L) return 0;
    
    payrecharge::rechargemgr::getInstance().removeobserver();
    
    return 1;
}

static int lualiosrechargeapi_addobserver(lua_State *L)
{
    if (!L) return 0;
    
    payrecharge::rechargemgr::getInstance().addobserver();
    
    return 1;
}

static void buycb(const char * productid, const char *orderid, const char *receipt)
{
    const char *functionname = "onbuycb";
    if(!localLuastate)
    {
        Err("Luastate is nil in %s", functionname); \
        return;
    }
    
    lua_getglobal(localLuastate, functionname);
    
    lua_pushstring(localLuastate, productid);
    
    lua_pushstring(localLuastate, orderid);
    
    lua_pushstring(localLuastate, receipt);
    
    if (lua_pcall(localLuastate, 3, 0, 0) != 0)
    {
        const char *errmsg = lua_tostring(localLuastate, -1);
        Err("luac: call lua function error : %s in %s!", errmsg, functionname); \
        lua_pop(localLuastate, 1);
    }
}

static void localfinishcb(const char *orderid, int state)
{
    const char *functionname = "onlocalfinishcb";

    if(!localLuastate)
    {
        Err("Luastate is nil in %s", functionname); \
        return;
    }
    lua_getglobal(localLuastate, functionname);
    
    lua_pushstring(localLuastate, orderid);
    lua_pushnumber(localLuastate, state);
    
    if (lua_pcall(localLuastate, 2, 0, 0) != 0)
    {
        const char *errmsg = lua_tostring(localLuastate, -1);
        Err("luac: call lua function error : %s in %s!", errmsg, functionname); \
        lua_pop(localLuastate, 1);
    }
}

static void openrunoncecb()
{
    const char *functionname = "registerrunonce";
    if(!localLuastate)
    {
        Err("Luastate is nil in %s", functionname); \
        return;
    }
    lua_getglobal(localLuastate, functionname);
    if(lua_pcall(localLuastate, 0, 0, 0) != 0)
    {
        const char *errmsg = lua_tostring(localLuastate, -1);
        Err("luac: call lua function error : %s in %s!", errmsg, functionname); \
        lua_pop(localLuastate, 1);
    }
}

static int lualiosrechargeapi_registercb(lua_State *L)
{
    if (!L) return 0;
    if(!localLuastate) localLuastate = L;
    payrecharge::rechargemgr::getInstance().registercb(buycb, localfinishcb, openrunoncecb);
    return 1;
}

static int lualiosrechargeapi_serverfinished(lua_State *L)
{
    if (!L) return 0;
    const char *orderid = (char *)luaL_checkstring(L, 1);
    payrecharge::rechargemgr::getInstance().serverfinished(orderid);
    return 1;
}

static int lualiosrechargeapi_serverfailed(lua_State *L)
{
    if (!L) return 0;
    const char *orderid = (char *)luaL_checkstring(L, 1);
    payrecharge::rechargemgr::getInstance().serverfailed(orderid);
    return 1;
}

static int lualiosrechargeapi_runOnce(lua_State *L)
{
    if (!L) return 0;
    float dt = luaL_checknumber(L, 1);
    payrecharge::rechargemgr::getInstance().runOnce(dt);
    return 1;
}

static const struct luaL_reg iosrechargeapi_function[] = {
    {"buy", lualiosrechargeapi_buy},
    {"removeobserver", lualiosrechargeapi_removeobserver},
    {"addobserver", lualiosrechargeapi_addobserver},
    {"registercb", lualiosrechargeapi_registercb},
    {"serverfinished", lualiosrechargeapi_serverfinished},
    {"serverfailed", lualiosrechargeapi_serverfailed},
    {"runOnce", lualiosrechargeapi_runOnce},
    {0, 0}
};

void lua_lualiosrechargeapi_register (lua_State *L)
{
    luaL_register(L, "iosrecharge", iosrechargeapi_function);
    lua_pop(L, 1);
}

