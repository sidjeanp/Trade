//+------------------------------------------------------------------+
//|                                                        Utils.mq5 |
//|                                       Sidnei Carlos Sousa Santos |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//#property library
#property copyright "Sidnei Carlos Sousa Santos"
#property link      "https://www.mql5.com"
#property version   "1.00"


struct MPositions{
   ulong                         order;            // Order ticket
   ulong                         position;         // Position ticket
   double                        price;            // Price
   ENUM_POSITION_TYPE            type;             // Order type
   datetime                      openTime;         // Data hora abertura
   datetime                      closeTime;         // Data hora abertura
 };
 
struct MDiasHoras{
  string dia;
  string inicio;
  string fim;
};

void TrataDiasParaOperar(string pOpDias,string &pDiasParaOperacao[]){
  StringSplit(pOpDias,';',pDiasParaOperacao);
  
  if(ArraySize(pDiasParaOperacao)==0){
    ArrayFree(pDiasParaOperacao);
    StringSplit("0;1;2;3;4;5;6",';',pDiasParaOperacao);
  }
} 

void TrataHorarioParaOperar(string pOpHorario,string pOpDiasHorarios,MDiasHoras &pHorasParaOperacao[]){
  string tempHorario = "";
  string tempHoras[];
  
  if((pOpHorario=="") && (pOpDiasHorarios=="")){
    tempHorario = "00:00:00-23:59:59";
  }
  else if((pOpHorario!="") && (pOpDiasHorarios=="")){
    tempHorario = pOpHorario;
  }
  
  Print("Horário: ", tempHorario);
  
  if(tempHorario!=""){
    if(tempHorario.Find(";")>=0){   
      StringSplit(tempHorario,';',tempHoras);
      for (int i=0; i< ArraySize(tempHoras) -1;i++){
        string temp[];
        StringSplit(tempHoras[i],'-',temp); 

        MDiasHoras mt;
        mt.dia = "";
        mt.inicio = temp[0];
        mt.fim = temp[1];
    
        ArrayResize(pHorasParaOperacao, ArraySize(tempHoras));
        pHorasParaOperacao[i] = mt;
      }
    }
    else{
      string temp[];
      StringSplit(tempHorario,'-',temp); 
 
      MDiasHoras mt;
      mt.dia = "";
      mt.inicio = temp[0];
      mt.fim = temp[1];
    
      ArrayResize(pHorasParaOperacao, 1);
      pHorasParaOperacao[0] = mt;    
    }
  }
} 
