page 80025 "PC Webservice Error FB"
{
    Caption = 'WebService Error';
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "PC Shopify Update Log";
   
    layout
    {
        area(Content)
        {
            field("Web Error";rec."Web Service Error")
            {
                ApplicationArea = All;
                Caption = 'Web Error';
                MultiLine = true;
            }
       }
    }
}