//+------------------------------------------------------------------+
//|                                               margin-protect.mqh |
//|                                  Copyright 2017, PHK Corporation |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, PHK Corporation"
#property link      "https://4xlots.com"
#property strict

#import "marginprotectlib.ex4"
   double CalculateMarginLevel();
   bool IsMarginLevelLessThan(double MarginLevelTest);
   void CloseAnOpenOrder(bool CloseNegativeOrder,double MaxLossForceClose);
   void CloseOpenOrders(bool closeNegativeOrders=true,int multiplier=2,double MaxLossForceClose=1.0);
   bool BreakEven(int MagicNumber);
   double RestoreSafeMarginLevel(string comment,int magic,double TP,double minsltp,double lots);
   double ProfitMoney(int MagicNumber);
   double TotalLots(int MagicNumber);
   string LastType(int MagicNumber);
   double LastPrice(int tip,int MagicNumber);
   void ModifyTP(int tip,double tp,int MagicNumber);
#import "stdlib.ex4"
   string ErrorDescription(int error_code);
   int    RGB(int red_value,int green_value,int blue_value);
   bool   CompareDoubles(double number1,double number2);
   string DoubleToStrMorePrecision(double number,int precision);
   string IntegerToHexString(int integer_number);
#import
//+------------------------------------------------------------------+
