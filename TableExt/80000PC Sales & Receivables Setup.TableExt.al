tableextension 80000 "PC Sales & Receivables Ext " extends "Sales & Receivables Setup" 
{
    fields
    {
        field(80000; "Shopify Connnect Url"; Text[150])
        {}
        field(80001; "Shopify API Key"; text[50])
        {}
        field(80002; "Shopify Password"; text[50])
        {}
        field(80003; "FulFilio Connnect Url"; Text[150])
        {}
        field(80004; "FulFilio Store ID"; integer)
        {}
        field(80005; "FulFilio Client ID"; text[100])
        {}
        field(80006; "FulFilio Client Secret"; text[100])
        {}
        field(80007; "FulFilio UserName"; text[80])
        {}
        field(80008; "FulFilio Password"; text[50])
        {}
        field(80009; "FulFilio Access Token"; text[100])
        {}
        field(80010; "FulFilio Refresh Token"; text[100])
        {}
        field(80011; "Dev Shopify Connnect Url"; Text[150])
        {}
        field(80012; "Dev Shopify API Key"; text[50])
        {}
        field(80013; "Dev Shopify Password"; text[50])
        {}
        field(80014; "Dev FulFilio Connnect Url"; Text[150])
        {}
        field(80015; "Dev FulFilio Store ID"; integer)
        {}
        field(80016; "Dev FulFilio Client ID"; text[100])
        {}
        field(80017; "Dev FulFilio Client Secret"; text[100])
        {}
        field(80018; "Dev FulFilio UserName"; text[80])
        {}
        field(80019; "Dev FulFilio Password"; text[50])
        {}
        field(80022; "Use Shopify Dev Access"; Boolean)
        {}
        field(80023; "Use Fulfilo Dev Access"; Boolean)
        {}
        field(80024; "Shopify Order No. Offset"; integer)
        {
        }
        field(80025; "Exception Email Address"; text[80])
        {}
        field(80026; "SPS Client ID"; text[50])
        {}
        field(80027; "SPS Secret Key"; text[80])
        {}
        field(80028; "SPS Token Date"; Date)
        {}
        field(80029; "SPS Access Token 1"; text[1000])
        {}
        field(80030; "SPS Access Token 2"; text[200])
        {}
        field(80031; "EDI Order Value Tolerance %"; Decimal)
        {}
        field(80032; "EDI Line Qty Tolerance %"; Decimal)
        {}
        field(80033; "EDI Line Value Tolerance %"; Decimal)
        {}
        field(80034; "EDI Del Date Tolerance Days"; integer)
        {}
        field(80035; "SPS EDI Auth Token Folder Path"; Text[80])
        {}
        field(80036; "SPS EDI Base Folder Path"; Text[80])
        {}

        field(80037; "SPS EDI Out Folder"; Text[30])
        {}
        field(80038; "SPS EDI In Folder"; Text[30])
        {}
        field(80039; "EDI Exception Email Address"; text[80])
        {}
        field(80040; "Bypass Date Filter"; boolean)
        {}
        field(80041; "PO CC email Address"; text[80])
        {}
        field(80050; "Gift Card Order Index"; Biginteger)
        {}




    }
}