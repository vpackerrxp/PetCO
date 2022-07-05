page 80023 "PC Shopify Update Log"
{
    Caption = 'Shopify Update Log';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "PC Shopify Update Log";
    InsertAllowed = false;
    ModifyAllowed = false;
   
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Error Date/Time"; rec."Error Date/Time")
                {
                    ApplicationArea = All;
                }
                field("Error Condition"; rec."Error Condition")
                {
                    ApplicationArea = All;
                }
           }
        }
        Area(FactBoxes)
        {
            part(WebServeError;"PC Webservice Error FB")
            {
                ApplicationArea = All;
                Caption = 'Picture';
                SubPageLink = ID = FIELD(ID);
           }
        }
   }
}