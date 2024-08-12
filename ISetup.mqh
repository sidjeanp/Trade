//+------------------------------------------------------------------+
//|                                                       ISetup.mqh |
//|                                         CopyRight 2024, Sidjeanp |
//|                                         https://www.sidjeanp.com |
//+------------------------------------------------------------------+
#property copyright "CopyRight 2024, Sidjeanp"
#property link      "https://www.sidjeanp.com"
#property version   "1.00"


interface ISetup{
 // void OnTickEvent(const MqlTick &pTick, ulong pPos);
  virtual ISetup* CreateInstance() const = 0;
};


