//+------------------------------------------------------------------+
//|                                               margin-protect.mqh |
//|   Copyright 2019-2020, PressPage Entertainment Inc DBA RedeeCash |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2020, PressPage Entertainment Inc DBA RedeeCash"
#property link      "https://4xlots.com"
#property strict

// minimum margin level before closing positive trades, 
// when this falls to 200, a margin call is at risk
extern double MarginLevelMin = 300;
// maximum loss per trade user will tolertate if force close out 
// negative trades to restore margin level to a safe leve
extern double MaxLossForceClose = -1.00;

#import "marginprotectlib.ex4"
   double CalculateMinMarginLevel();
   double CalculateMarginLevel();
   bool IsMarginLevelLessThan(double MarginLevelTest);
   void CloseAnOpenOrder(bool CloseNegativeOrder,double MaxLossForceClose);
   void CloseOpenOrders(bool closeNegativeOrders=true,int multiplier=2);
   bool BreakEven(int MagicNumber);
   double RestoreSafeMarginLevel(string comment,int magic,double TP,double minsltp,double lots);
   double ProfitMoney(int MagicNumber);
   double TotalLots(int MagicNumber);
   string LastType(int MagicNumber);
   double LastPrice(int tip,int MagicNumber);
   void ModifyTP(int tip,double tp,int MagicNumber);
   int TotalOrders(int MagicNumber);
#import "stdlib.ex4"
   string ErrorDescription(int error_code);
   int    RGB(int red_value,int green_value,int blue_value);
   bool   CompareDoubles(double number1,double number2);
   string DoubleToStrMorePrecision(double number,int precision);
   string IntegerToHexString(int integer_number);
#import
//+------------------------------------------------------------------+
