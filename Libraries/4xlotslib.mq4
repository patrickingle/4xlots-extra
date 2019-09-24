//+------------------------------------------------------------------+
//|                                                    4xlotslib.mq4 |
//|        Copyright 2019, PressPage Entertainment Inc DBA RedeeCash |
//|                                           https://www.4xlots.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2019, PressPage Entertainment Inc DBA RedeeCash"
#property link      "https://www.4xlots.com"
#property version   "2.00"
#property strict

#include <4xlots.mqh>
#include <mql4-http.mqh>


//+------------------------------------------------------------------+
//| LotsOptimize                                                      |
//+------------------------------------------------------------------+
double LotsOptimize(double deposit,int preserve) export
{
   double lots = 0.0;
   string strResult = "0.0";
   
   double equity = AccountEquity();

   int leverage = AccountLeverage();
   if (LeverageOverride != -1 && leverage != LeverageOverride) {
      leverage = LeverageOverride;
   }

   double minlots = MarketInfo(Symbol(), MODE_MINLOT);
   double maxlots = MarketInfo(Symbol(), MODE_MAXLOT);
   
   string str = "accesskey=" + AccessKey;
   str = str + "&deposit=" + DoubleToStr(deposit);
   str = str + "&equity=" + DoubleToStr(equity);
   str = str + "&leverage=" + IntegerToString(leverage);
   str = str + "&minlots=" + DoubleToStr(minlots);
   str = str + "&maxlots=" + DoubleToStr(maxlots);
   str = str + "&preserve=" + IntegerToString(preserve);
   
   string api_4xlots = ENDPOINT + "?" + str;
   
   string sLots = httpGET(api_4xlots);
   lots = StringToDouble(sLots);
   
   return lots;
}


//+------------------------------------------------------------------+
