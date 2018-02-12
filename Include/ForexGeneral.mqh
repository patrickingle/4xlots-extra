//+------------------------------------------------------------------+
//|                                                 ForexGeneral.mqh |
//|                                    Copyright 2018, RedeeCash LTD |
//|                                        https://forexgeneral.info |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, RedeeCash LTD"
#property link      "https://forexgeneral.info"
#property strict

extern string  TradePanelIPAddress = "192.168.0.110";
extern int     TradePanelPort = 8080;
extern bool    TradePanelConnectSecure = false;

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define VERSION      "2018"
#define BUILD_DATE   "2018-02-11"

//
// Metatrader Error Messages
//
#define ERR_NO_ERROR                      0 //No error returned. 
#define ERR_NO_RESULT                     1 //No error returned, but the result is unknown. 
#define ERR_COMMON_ERROR                  2 //Common error. 
#define ERR_INVALID_TRADE_PARAMETERS      3 //Invalid trade parameters. 
#define ERR_SERVER_BUSY                   4 //Trade server is busy. 
#define ERR_OLD_VERSION                   5 //Old version of the client terminal. 
#define ERR_NO_CONNECTION                 6 //No connection with trade server. 
#define ERR_NOT_ENOUGH_RIGHTS             7 //Not enough rights. 
#define ERR_TOO_FREQUENT_REQUESTS         8 //Too frequent requests. 
#define ERR_MALFUNCTIONAL_TRADE           9 //Malfunctional trade operation. 
#define ERR_ACCOUNT_DISABLED              64 //Account disabled. 
#define ERR_INVALID_ACCOUNT               65 //Invalid account. 
#define ERR_TRADE_TIMEOUT                 128 //Trade timeout. 
#define ERR_INVALID_PRICE                 129 //Invalid price. 
#define ERR_INVALID_STOPS                 130 //Invalid stops. 
#define ERR_INVALID_TRADE_VOLUME          131 //Invalid trade volume. 
#define ERR_MARKET_CLOSED                 132 //Market is closed. 
#define ERR_TRADE_DISABLED                133 //Trade is disabled. 
#define ERR_NOT_ENOUGH_MONEY              134 //Not enough money. 
#define ERR_PRICE_CHANGED                 135 //Price changed. 
#define ERR_OFF_QUOTES                    136 //Off quotes. 
#define ERR_BROKER_BUSY                   137 //Broker is busy. 
#define ERR_REQUOTE                       138 //Requote. 
#define ERR_ORDER_LOCKED                  139 //Order is locked. 
#define ERR_LONG_POSITIONS_ONLY_ALLOWED   140 //Long positions only allowed. 
#define ERR_TOO_MANY_REQUESTS             141 //Too many requests. 
#define ERR_TRADE_MODIFY_DENIED           145 //Modification denied because order too close to market. 
#define ERR_TRADE_CONTEXT_BUSY            146 //Trade context is busy. 
#define ERR_TRADE_EXPIRATION_DENIED       147 //Expirations are denied by broker. 
#define ERR_TRADE_TOO_MANY_ORDERS         148 //The amount of open and pending orders has reached the limit set by the broker. 
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
#import "fxgenlib.ex4"
   string GetVersion();
   string GetTradeCurrency(int session);
   string GetTradeCurrency2(int session);
   string GetTradeCurrency3(int session);

   int FindExistingSession(int acctnum,int handle,string symbol);
	int Initialize(int acctnum,int handle,string symbol,string ccy1,string ccy2,string ccy3);
	int DeInitialize(int session);
   int GetSessionCount();
   int SetBidAsk(int index,double bid,double ask,double close,double vol);
   int SaveAccountInfo(int session,int number,double balance,double equity,int leverage);
   int SaveCurrencySessionInfo(int session,string symbol,int handle,int period,int number);
   int DecrementQueuePosition(int session);
   int SaveMarketInfo(int session,int number,int leverage,string symbol,double points,double digits,double spread,double stoplevel);
   int SaveMarginInfo(int session,string symbol,int handle,double margininit,double marginmaintenance,double marginhedged,double marginrequired,double margincalcmode);
   int GetTradeOpCommand(int session);
   int GetTradeOpCommand1(int session);
   int GetTradeOpCommand2(int session);
   int GetTradeOpCommand3(int session);
   int SaveHistory(int session,string symbol,double &rates[][6],int rates_total,int handle);
   int SaveHistoryCcy1(int session,string symbol,double &rates[][6],int rates_total,int handle);
   int SaveHistoryCcy2(int session,string symbol,double &rates[][6],int rates_total,int handle);
   int SaveHistoryCcy3(int session,string symbol,double &rates[][6],int rates_total,int handle);
   double RetrieveHistoricalOpen(int session,int index);
   int SendResponse(int session,int errorcode,int respcode,string message,int ticket);
   double GetTradePrice(int session);
   double GetTradeLots(int session);
   double GetTradeLots2(int session);
   double GetTradeLots3(int session);
   double GetTradeStoploss(int session);
   double GetTradeTakeprofit(int session);
   void ResetTradeCommand(int session);
   void SetSwapRateLong(int session,double rate);
   void SetSwapRateShort(int session,double rate);
   
   void StopScript();
#import "speak_b6.dll"
   //
   // GSpeak DLL Function Definitions
   //
   bool gSpeak(string text, int rate, int volume);
#import
//+------------------------------------------------------------------+
