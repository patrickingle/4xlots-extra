//+------------------------------------------------------------------+
//|                                                       4xlots.mq4 |
//|                             Copyright 2011-2017, PHK Corporation |
//|                                           https://www.4xlots.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2011-2017, PHK Corporation"
#property link      "https://www.4xlots.com"
#property version   "2.00"
#property strict

#include <4xlots.mqh>


//+------------------------------------------------------------------+
//| LotsOptimize                                                      |
//+------------------------------------------------------------------+
double LotsOptimize(double deposit,int preserve) export
{
   string cookie=NULL,headers;
   char post[],result[];
   int res;
   int timeout=5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   double lots = 0.0;
   string strResult = "0.0";
   
   char params[];
  
   double equity = AccountEquity();

   int leverage = AccountLeverage();
   if (leverage != LeverageOverride) {
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
   
   if (IsTesting()) {
      string sLots = httpGET(api_4xlots);
      lots = StringToDouble(sLots);
   } else {
      headers = "";
      ResetLastError(); 
      res=WebRequest("GET",api_4xlots,cookie,NULL,timeout,post,0,result,headers); 

      if(res==-1) {
         lots = 0.0;
      } else {
         for(int i=0;i<ArraySize(result);i++) {
    	     if( (result[i] == 10) || (result[i] == 13)) {
	        continue;
	     } else {
	        strResult += CharToStr(result[i]);
	     }
         } 
      }
      lots = StringToDouble(strResult);
   }
   
   return lots;
}
//+------------------------------------------------------------------+
