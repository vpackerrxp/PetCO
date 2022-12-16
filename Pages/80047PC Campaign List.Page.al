page 80047 "PC Campaign List"
{
    ApplicationArea = All;
    Caption = 'Campaign List';
    PageType = List;
    SourceTable = "PC Campaign Rebates";
    SourceTableTemporary = true;
    UsageCategory = Lists;
    Editable = False;
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Campaign; Rec.Campaign)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    trigger OnInit()
    var
        CReb:record "PC Campaign Rebates";
        Cmp:Code[20];
    Begin
        If Not Rec.IsEmpty Then Rec.DeleteAll();
        CReb.Reset;
        Creb.SetCurrentKey(Campaign);
        CReb.Setrange("Rebate Type",CReb."Rebate Type"::Campaign);
        If CReb.findset then
        repeat
            If Cmp <> CReb.Campaign then
            begin
                Cmp := CReb.Campaign;
                rec.copy(CReb);
                Rec.insert();
            end;
        until CReb.next = 0;
    end;
}
