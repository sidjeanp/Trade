//+------------------------------------------------------------------+
//|                                             CrossMediaMoving.mqh |
//|                                         CopyRight 2024, Sidjeanp |
//|                                         https://www.sidjeanp.com |
//+------------------------------------------------------------------+
#property copyright "CopyRight 2024, Sidjeanp"
#property link      "https://www.sidjeanp.com"
#property version   "1.00"

#include <Sidjeanp/Bot/ISetup.mqh>
#include <Sidjeanp/Bot/Utils.mqh>
#include <Sidjeanp/Bot/MediaMoving.mqh>
#include <Arrays\ArrayObj.mqh>

class CCrossMediaMoving : public ISetup{
private:
  CMediaMoving* oMediaMov;
  double zonaNotOpe;
  ENUM_TO_OPERATION_TYPE statusMedias;
  
  ENUM_TO_OPERATION_TYPE buySell;
  bool operar;
  bool operInZone;
  
  CTrade trade;
  
  void DefineOperacao(ENUM_TO_OPERATION_TYPE &pBuySell, bool &pOperar, bool &poperInZone, double &mediaRapida[], double &mediaLenta[]);  

public:
   CCrossMediaMoving(string ltsMedias,CTrade &pTrade);
   CCrossMediaMoving();
   ~CCrossMediaMoving();
   
   void IncluiListaMedias(string ltsMedias);
   void AddMedia(string sMedia);
   void OnTickEvent();
   void SetZonaNotOpe(double valor);
   ENUM_TO_OPERATION_TYPE GetStatusMedias();
   ENUM_TO_OPERATION_TYPE GetBuySell();
   bool GetOperar();   

   ISetup* CreateInstance() const override {
     return new CCrossMediaMoving();
   }   
};

CCrossMediaMoving::CCrossMediaMoving(){
  oMediaMov   = new CMediaMoving();
  zonaNotOpe = 0;
}

CCrossMediaMoving::~CCrossMediaMoving(){
  delete oMediaMov;
}

CCrossMediaMoving::CCrossMediaMoving(string ltsMedias,CTrade &pTrade){
  trade = pTrade;
  CCrossMediaMoving();
  IncluiListaMedias(ltsMedias);
}

void CCrossMediaMoving::IncluiListaMedias(string ltsMedias){
  string sMedias[];
  
  ArrayFree(sMedias);
     
  StringSplit(ltsMedias,'|',sMedias);
  
  if(ArraySize(sMedias) > 1){
    for(int i=0;i<ArraySize(sMedias);i++){
      AddMedia(sMedias[i]);  
    }
  }
}

void CCrossMediaMoving::AddMedia(string sMedia){
  string eMedia[];
  MMediaMov novaMedia;
  
  StringSplit(sMedia,';',eMedia);
 
 if(eMedia[0][0] != "#"){
 
   if(oMediaMov.BuscaMedia(eMedia[0]) == 0){ 
      novaMedia.symbol = _Symbol; // Símbolo atual
      novaMedia.period = _Period; // Período M15
      novaMedia.nameMediaMovel = eMedia[0];
      novaMedia.mediaPeriodo = eMedia[1];
      novaMedia.ma_metodo = StrToMA_METHOD(eMedia[2]);
      novaMedia.ma_preco = StrToAPPLIED_PRICE(eMedia[3]);
      novaMedia.lineColor = StrToColor(eMedia[4]);
     
      oMediaMov.AddMedia(novaMedia);
    }
  }
  
  //oMediaMov.AtualizaMedias();
  
}

void CCrossMediaMoving::OnTickEvent(){
  oMediaMov.AtualizaMedias();
  CheckStatusMedias(statusMedias, 
                    oMediaMov.ListaIma[oMediaMov.BuscaMedia("MRapida")].mediaArray, 
                    oMediaMov.ListaIma[oMediaMov.BuscaMedia("MLenta")].mediaArray, 
                    zonaNotOpe );
                    
  DefineOperacao(buySell, operar, operInZone,
                 oMediaMov.ListaIma[oMediaMov.BuscaMedia("MRapida")].mediaArray, 
                 oMediaMov.ListaIma[oMediaMov.BuscaMedia("MLenta")].mediaArray );                    
}

void CCrossMediaMoving::SetZonaNotOpe(double valor){
  zonaNotOpe = valor;
}

ENUM_TO_OPERATION_TYPE CCrossMediaMoving::GetStatusMedias(){
  return statusMedias;
}

bool CCrossMediaMoving::GetOperar(){
  return operar;
}

ENUM_TO_OPERATION_TYPE CCrossMediaMoving::GetBuySell(){
  return buySell;
}

void DefineOperacao(ENUM_TO_OPERATION_TYPE &pBuySell, bool &pOperar, bool &poperInZone, double &mediaRapida[], double &mediaLenta[]){
  pBuySell = UNDEF;
  pOperar = false;
  poperInZone = false;
  
 
  if((mediaMov.ListaIma[0].mediaArray[0] - (zonaNotOpe*_Point)>mediaMov.ListaIma[1].mediaArray[0]) && 
     (mediaMov.ListaIma[0].mediaArray[2] < mediaMov.ListaIma[1].mediaArray[2])// && (spread <= spredMax)
     ){
    pBuySell = TO_BUY;//Fazer compra
    pOperar = true;
    poperInZone = true; 
  }
  
  if((mediaMov.ListaIma[0].mediaArray[0] + (zonaNotOpe*_Point)<mediaMov.ListaIma[1].mediaArray[0]) && 
     (mediaMov.ListaIma[0].mediaArray[2] > mediaMov.ListaIma[1].mediaArray[2]) //&& (spread <= spredMax)
     ){
    pBuySell = TO_SELL;//Fazer venda
    operar = true; 
    poperInZone = true;  
  }
}