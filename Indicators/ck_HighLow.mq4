//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property copyright "� 2007 RickD"
#property link      "www.e2e-fx.net"

#define major 1
#define minor 0

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_color1  Gold
#property indicator_color2  DodgerBlue
#property indicator_color3 PowderBlue
#property indicator_color4 LightGreen
#property indicator_color5 Silver
#property indicator_color6 LightBlue
#property indicator_color7 Khaki
#property indicator_color8 Gainsboro
/*extern*/ int N = 20;
/*extern*/ int N2 = 5;

double UpperBuf[];
double LowerBuf[];
double ArrBuf2[];
double ArrBuf3[];
double ArrBuf4[];
double ArrBuf5[];
double ArrBuf6[];
double ArrBuf7[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void init() {
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(5, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(6, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(7, DRAW_LINE, STYLE_SOLID, 1);

   SetIndexDrawBegin(0, N);
   SetIndexDrawBegin(1, N);
   SetIndexDrawBegin(2, N);
   SetIndexDrawBegin(3, N);
   SetIndexDrawBegin(4, N);
   SetIndexDrawBegin(5, N);
   SetIndexDrawBegin(6, N);
   SetIndexDrawBegin(7, N);

   SetIndexBuffer(0, UpperBuf);
   SetIndexBuffer(1, LowerBuf);
   SetIndexBuffer(2, ArrBuf2);
   SetIndexBuffer(3, ArrBuf3);
   SetIndexBuffer(4, ArrBuf4);
   SetIndexBuffer(5, ArrBuf5);
   SetIndexBuffer(6, ArrBuf6);
   SetIndexBuffer(7, ArrBuf7);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deinit() {

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void start() {
   int counted = IndicatorCounted();

   if(counted < 0)
      return (-1);

   if(counted > 0)
      counted--;
   int limit = Bars - counted;

   for(int i = 0; i < limit; i++) {
      /*input*/ double Lots = 0.01;
      /*input*/ int atrPeriod = 14;
      /*input*/ int MovingShift = 1;
      /*input*/ int emaPeriod20 = 14;
      /*input*/ int emaPeriod50 = 28;
      /*input*/ int emaPeriod70 = 112;
      /*input*/ int emaCriteriaContinousCount = 14; //bars
      /*input*/ int highLowRangePeriod = 2;         //hour
      /*input*/ double stopLossRatio = 3.5;
      /*input*/ double takeProfitRatio = 2 * stopLossRatio;

      double ema20_s1 = iMA(NULL, PERIOD_H1, emaPeriod20, 0, MODE_EMA, PRICE_CLOSE, i + 0);
      double ema20_s3 = iMA(NULL, PERIOD_H1, emaPeriod20, 0, MODE_EMA, PRICE_CLOSE, i + 1);
      double ema20_s5 = iMA(NULL, PERIOD_H1, emaPeriod20, 0, MODE_EMA, PRICE_CLOSE, i + 2);

      double ema50_s1 = iMA(NULL, PERIOD_H1, emaPeriod50, 0, MODE_EMA, PRICE_CLOSE, i + 0);
      double ema50_s3 = iMA(NULL, PERIOD_H1, emaPeriod50, 0, MODE_EMA, PRICE_CLOSE, i + 1);
      double ema50_s5 = iMA(NULL, PERIOD_H1, emaPeriod50, 0, MODE_EMA, PRICE_CLOSE, i + 2);

      double ema70_s1 = iMA(NULL, PERIOD_H1, emaPeriod70, 0, MODE_EMA, PRICE_CLOSE, i + 0);
      double ema70_s3 = iMA(NULL, PERIOD_H1, emaPeriod70, 0, MODE_EMA, PRICE_CLOSE, i + 1);
      double ema70_s5 = iMA(NULL, PERIOD_H1, emaPeriod70, 0, MODE_EMA, PRICE_CLOSE, i + 2);

      double ema20_1H = iMA(NULL, PERIOD_H4, emaPeriod20, 0, MODE_EMA, PRICE_CLOSE, i + 1);
      double ema20_3H = iMA(NULL, PERIOD_H4, emaPeriod20, 0, MODE_EMA, PRICE_CLOSE, i + 3);
      double ema20_5H = iMA(NULL, PERIOD_H4, emaPeriod20, 0, MODE_EMA, PRICE_CLOSE, i + 5);

      double ema20_1W = iMA(NULL, PERIOD_W1, emaPeriod20, 0, MODE_EMA, PRICE_CLOSE, i + 1);
      double ema20_2W = iMA(NULL, PERIOD_W1, emaPeriod20, 0, MODE_EMA, PRICE_CLOSE, i + 2);
      double ema20_3W = iMA(NULL, PERIOD_W1, emaPeriod20, 0, MODE_EMA, PRICE_CLOSE, i + 3);

      double atr = iATR(NULL, PERIOD_H1, atrPeriod, i + 1);
      double periodHigh = iHigh(NULL, PERIOD_H1, iHighest(NULL, PERIOD_H1, MODE_HIGH, highLowRangePeriod, i + 1));
      double periodLow = iLow(NULL, PERIOD_H1, iLowest(NULL, PERIOD_H1, MODE_LOW, highLowRangePeriod, i + 1));

      UpperBuf[i] = periodHigh;
      LowerBuf[i] = periodLow;
      
      ArrBuf2[i] = ema20_s1;
      ArrBuf3[i] = ema20_s3;
      ArrBuf4[i] = ema20_s5;

      ArrBuf5[i] = ema50_s1;
      ArrBuf6[i] = ema50_s3;
      ArrBuf7[i] = ema50_s5;

      // UpperBuf[i] = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, N, i)) + N2*Point;
      // LowerBuf[i] = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, N, i)) - N2*Point;
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
