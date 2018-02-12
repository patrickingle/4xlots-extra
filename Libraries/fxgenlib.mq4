//+------------------------------------------------------------------+
//|                                                     fxgenlib.mq4 |
//|                                    Copyright 2018, RedeeCash LTD |
//|                                        https://forexgeneral.info |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2018, RedeeCash LTD"
#property link      "https://forexgeneral.info"
#property version   "1.00"
#property strict

#include <ForexGeneral.mqh>
#include <mql4-http.mqh>

string Endpoint(string ipAddress,int port,bool secure=false) 
{
   if (secure == true) {
      return StringConcatenate("https://",ipAddress,":",IntegerToString(port),"/");
   }
   return StringConcatenate("http://",ipAddress,":",IntegerToString(port),"/");
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
string GetVersion() export
{
   string url = StringConcatenate(Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),"GetVersion");
   return httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
string GetTradeCurrency(int session) export
{
   string url = StringConcatenate(Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),"GetTradeCurrency/",IntegerToString(session));
   return httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
string GetTradeCurrency2(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeCurrency2/",
                  IntegerToString(session)
                );
   return httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
string GetTradeCurrency3(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeCurrency3/",
                  IntegerToString(session)
                );
   return httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int FindExistingSession(int acctnum,int handle,string symbol) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "FindExistingSession/",
                  IntegerToString(acctnum),"/",
                  IntegerToString(handle),"/",
                  symbol
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int Initialize(int acctnum,int handle,string symbol,string ccy1,string ccy2,string ccy3) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "Initialize/",
                  IntegerToString(acctnum),"/",
                  IntegerToString(handle),"/",
                  symbol,"/",
                  ccy1,"/",
                  ccy2,"/",
                  ccy3
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int DeInitialize(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "DeInitialize/",
                  IntegerToString(session)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int GetSessionCount() export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetSessionCount"
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int SetBidAsk(int index,double bid,double ask,double close,double vol) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SetBidAsk/",
                  IntegerToString(index),"/",
                  DoubleToString(bid),"/",
                  DoubleToString(ask),"/",
                  DoubleToString(close),"/",
                  DoubleToString(vol)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int SaveAccountInfo(int session,int number,double balance,double equity,int leverage) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SaveAccountInfo/",
                  IntegerToString(session),"/",
                  IntegerToString(number),"/",
                  DoubleToString(balance),"/",
                  DoubleToString(equity),"/",
                  DoubleToString(leverage)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int SaveCurrencySessionInfo(int session,string symbol,int handle,int period,int number) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SaveCurrencySessionInfo/",
                  IntegerToString(session),"/",
                  symbol,"/",
                  IntegerToString(handle),"/",
                  IntegerToString(period),"/",
                  IntegerToString(number)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int DecrementQueuePosition(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "DecrementQueuePosition/",
                  IntegerToString(session)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int SaveMarketInfo(int session,int number,int leverage,string symbol,double points,double digits,double spread,double stoplevel) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SaveMarketInfo/",
                  IntegerToString(session),"/",
                  IntegerToString(number),"/",
                  IntegerToString(leverage),"/",
                  symbol,"/",
                  DoubleToString(points),"/",
                  DoubleToString(digits),"/",
                  DoubleToString(spread),"/",
                  DoubleToString(stoplevel)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int SaveMarginInfo(int session,string symbol,int handle,double margininit,double marginmaintenance,double marginhedged,double marginrequired,double margincalcmode) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SaveMarginInfo/",
                  IntegerToString(session),"/",
                  symbol,"/",
                  IntegerToString(handle),"/",
                  DoubleToString(margininit),"/",
                  DoubleToString(marginmaintenance),"/",
                  DoubleToString(marginhedged),"/",
                  DoubleToString(marginrequired),"/",
                  DoubleToString(margincalcmode)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int GetTradeOpCommand(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeOpCommand/",
                  IntegerToString(session)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int GetTradeOpCommand1(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeOpCommand1/",
                  IntegerToString(session)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int GetTradeOpCommand2(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeOpCommand2/",
                  IntegerToString(session)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int GetTradeOpCommand3(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeOpCommand3/",
                  IntegerToString(session)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int SaveHistory(int session,string symbol,double &rates[][6],int rates_total,int handle) export
{
   int max = ArrayMaximum(rates);
   string _rates = "";
   for (int i=0; i<max; i++) {
      double temp[6];
      temp[0] = rates[i][0];
      temp[1] = rates[i][1];
      temp[2] = rates[i][2];
      temp[3] = rates[i][3];
      temp[4] = rates[i][4];
      temp[5] = rates[i][5];
      _rates = StringConcatenate(_rates,"[",
                                 temp[0],",",
                                 temp[1],",",
                                 temp[2],",",
                                 temp[3],",",
                                 temp[4],",",
                                 temp[5],"]");
      if (i < max) {
         _rates = StringConcatenate(_rates,",");
      }
   }
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SaveHistory/",
                  IntegerToString(session),"/",
                  symbol,"/",
                  "{",_rates,"}/",
                  IntegerToString(rates_total),"/",
                  IntegerToString(handle)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int SaveHistoryCcy1(int session,string symbol,double &rates[][6],int rates_total,int handle) export
{
   int max = ArrayMaximum(rates);
   string _rates = "";
   for (int i=0; i<max; i++) {
      double temp[6];
      temp[0] = rates[i][0];
      temp[1] = rates[i][1];
      temp[2] = rates[i][2];
      temp[3] = rates[i][3];
      temp[4] = rates[i][4];
      temp[5] = rates[i][5];
      _rates = StringConcatenate(_rates,"[",
                                 temp[0],",",
                                 temp[1],",",
                                 temp[2],",",
                                 temp[3],",",
                                 temp[4],",",
                                 temp[5],"]");
      if (i < max) {
         _rates = StringConcatenate(_rates,",");
      }
   }
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SaveHistoryCcy1/",
                  IntegerToString(session),"/",
                  symbol,"/",
                  "{",_rates,"}/",
                  IntegerToString(rates_total),"/",
                  IntegerToString(handle)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int SaveHistoryCcy2(int session,string symbol,double &rates[][6],int rates_total,int handle) export
{
   int max = ArrayMaximum(rates);
   string _rates = "";
   for (int i=0; i<max; i++) {
      double temp[6];
      temp[0] = rates[i][0];
      temp[1] = rates[i][1];
      temp[2] = rates[i][2];
      temp[3] = rates[i][3];
      temp[4] = rates[i][4];
      temp[5] = rates[i][5];
      _rates = StringConcatenate(_rates,"[",
                                 temp[0],",",
                                 temp[1],",",
                                 temp[2],",",
                                 temp[3],",",
                                 temp[4],",",
                                 temp[5],"]");
      if (i < max) {
         _rates = StringConcatenate(_rates,",");
      }
   }
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SaveHistoryCcy2/",
                  IntegerToString(session),"/",
                  symbol,"/",
                  "{",_rates,"}/",
                  IntegerToString(rates_total),"/",
                  IntegerToString(handle)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int SaveHistoryCcy3(int session,string symbol,double &rates[][6],int rates_total,int handle) export
{
   int max = ArrayMaximum(rates);
   string _rates = "";
   for (int i=0; i<max; i++) {
      double temp[6];
      temp[0] = rates[i][0];
      temp[1] = rates[i][1];
      temp[2] = rates[i][2];
      temp[3] = rates[i][3];
      temp[4] = rates[i][4];
      temp[5] = rates[i][5];
      _rates = StringConcatenate(_rates,"[",
                                 temp[0],",",
                                 temp[1],",",
                                 temp[2],",",
                                 temp[3],",",
                                 temp[4],",",
                                 temp[5],"]");
      if (i < max) {
         _rates = StringConcatenate(_rates,",");
      }
   }
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SaveHistoryCcy3/",
                  IntegerToString(session),"/",
                  symbol,"/",
                  "{",_rates,"}/",
                  IntegerToString(rates_total),"/",
                  IntegerToString(handle)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
double RetrieveHistoricalOpen(int session,int index) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "RetrieveHistoricalOpen/",
                  IntegerToString(session),"/",
                  IntegerToString(index)
                );
   return (double)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
int SendResponse(int session,int errorcode,int respcode,string message,int ticket) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SendResponse/",
                  IntegerToString(session),"/",
                  IntegerToString(errorcode),"/",
                  IntegerToString(respcode),"/",
                  message,"/",
                  IntegerToString(ticket)
                );
   return (int)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
double GetTradePrice(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradePrice/",
                  IntegerToString(session)
                );
   return (double)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
double GetTradeLots(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeLots/",
                  IntegerToString(session)
                );
   return (double)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
double GetTradeLots2(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeLots2/",
                  IntegerToString(session)
                );
   return (double)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
double GetTradeLots3(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeLots3/",
                  IntegerToString(session)
                );
   return (double)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
double GetTradeStoploss(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeStopLoss/",
                  IntegerToString(session)
                );
   return (double)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
double GetTradeTakeprofit(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "GetTradeTakeprofit/",
                  IntegerToString(session)
                );
   return (double)httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
void ResetTradeCommand(int session) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "ResetTradeCommand/",
                  IntegerToString(session)
                );
   httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
void SetSwapRateLong(int session,double rate) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SetSwapRateLong/",
                  IntegerToString(session),"/",
                  DoubleToString(rate)
                );
   httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
void SetSwapRateShort(int session,double rate) export
{
   string url = StringConcatenate(
                  Endpoint(TradePanelIPAddress,TradePanelPort,TradePanelConnectSecure),
                  "SetSwapRateShort/",
                  IntegerToString(session),"/",
                  DoubleToString(rate)
                );
   httpGET(url);
}

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
void StopScript() export
{
   ExpertRemove();
}
//+------------------------------------------------------------------+
