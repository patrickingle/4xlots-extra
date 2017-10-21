//+------------------------------------------------------------------+
//|                                               margin-protect.mqh |
//|                                  Copyright 2017, PHK Corporation |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, PHK Corporation"
#property link      "https://4xlots.com"
#property strict

#import "margin-protect.ex4"
   bool IsMarginLevelLessThan(double MarginLevelTest);
   void CloseAnOpenOrder(bool CloseNegativeOrder,double MaxLossForceClose);
#import "stdlib.ex4"
   string ErrorDescription(int error_code);
   int    RGB(int red_value,int green_value,int blue_value);
   bool   CompareDoubles(double number1,double number2);
   string DoubleToStrMorePrecision(double number,int precision);
   string IntegerToHexString(int integer_number);
#import
//+------------------------------------------------------------------+
