#property copyright "CopyRight 2024, Sidjeanp"
#property link      "https://www.sidjeanp.com"
#property version   "1.00"

#include <Arrays\ArrayObj.mqh>
#include <Object.mqh>
#include <Indicators\Indicators.mqh>

struct MMediaMov {
    string nameMediaMovel;
    int mediaHandle;
    string symbol;
    ENUM_TIMEFRAMES period;
    int mediaPeriodo;
    double mediaArray[];
    ENUM_MA_METHOD ma_metodo;
    ENUM_APPLIED_PRICE ma_preco;
    color    lineColor;

};

class CMediaMoving {
private:
    MMediaMov Param;

public:
    MMediaMov ListaIma[];

    void AddMedia(MMediaMov &pParam);
    int BuscaMedia(string nomeMedia);
    void CriarMedia(MMediaMov &pParam);
    void AtualizaConfiguracao(const MMediaMov &novaConfiguracao);
    void AtualizaUltimoTick();
    void AtualizaMedias();

    CMediaMoving(MMediaMov &pParam);
    CMediaMoving();
    ~CMediaMoving();
};


void CMediaMoving::AddMedia(MMediaMov &pParam){
  if(BuscaMedia(pParam.nameMediaMovel) < 0){
    CriarMedia(pParam);
  }
  
}
int CMediaMoving::BuscaMedia(string nomeMedia){
  for (int i = 0; i < ArraySize(ListaIma); i++) {
    if(ListaIma[i].nameMediaMovel == nomeMedia){
      return i;
    }
  }
  
  return -1;
  
}

void CMediaMoving::CriarMedia(MMediaMov &pParam){
    MMediaMov novaMedia;
    novaMedia.mediaHandle = iCustom(pParam.symbol,pParam.period,"Downloads\Custom Moving Average Inputs", pParam.mediaPeriodo,0,pParam.ma_metodo,pParam.lineColor,2,pParam.ma_preco);
    
    novaMedia.symbol = pParam.symbol;
    novaMedia.period = pParam.period;
    novaMedia.mediaPeriodo = pParam.mediaPeriodo;
    novaMedia.ma_metodo = pParam.ma_metodo;
    novaMedia.ma_preco = pParam.ma_preco;
    novaMedia.lineColor = pParam.lineColor;

    int size = ArraySize(ListaIma);
    ArrayResize(ListaIma, size + 1);
    ListaIma[size] = pParam;
     
    ArraySetAsSeries(ListaIma[size].mediaArray, true);    
}

void CMediaMoving::AtualizaConfiguracao(const MMediaMov &novaConfiguracao) {
    Param = novaConfiguracao;
}

CMediaMoving::CMediaMoving(MMediaMov &pParam) {
    Param = pParam;
    AddMedia(pParam);
}

CMediaMoving::CMediaMoving() {}

CMediaMoving::~CMediaMoving() {
    for (int i = 0; i < ArraySize(ListaIma); i++) {
        ListaIma[i].mediaHandle = INVALID_HANDLE;
    }
}

void CMediaMoving::AtualizaMedias() {
    for (int i = 0; i < ArraySize(ListaIma); i++) {
        if (CopyBuffer(ListaIma[i].mediaHandle, 0, 0, 3, ListaIma[i].mediaArray) < 0) {
            Print("Erro ao copiar dados da média móvel: " + IntegerToString(i) + " - " + GetLastError());
        }

    }   
   
}



