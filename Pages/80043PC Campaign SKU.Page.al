page 80043 "PC Campaign SKU"
{
    ApplicationArea = All;
    Caption = 'Campaign SKU';
    PageType = Worksheet;
    SourceTable = "PC Campaign SKU";
    UsageCategory = Lists;
    InsertAllowed = false;
    DeleteAllowed = false;
     
    layout
    {
        area(content)
        {
            Group(A)
            {
                ShowCaption = false;
                field("Rebate Supplier";CmpReb."Rebate Supplier No.")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = False;
                }
                field("Campaign Start Date"; CmpReb."Campaign Start Date")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Visible = ShowFlg;
                    Editable = False;
                }
                field("Campaign End Date"; CmpReb."Campaign End Date")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Visible = ShowFlg;
                    Editable = False;
                }
            }
            repeater(General)
            {
                field(Campaign; Rec.Campaign)
                {
                    ApplicationArea = All;
                }
                field(SKU; Rec.SKU)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        Item:Record Item;
                        PG:Page "Item Card";
                    Begin
                        Item.Get(Rec.SKU);
                        PG.SetRecord(Item);
                        Pg.RunModal();
                    End;
                }
                field(Description;rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Campaign Price"; Rec."Campaign Price")
                {
                    ApplicationArea = All;
                    Visible = ShowFlg;
                }
                field("Rebate Amount"; Rec."Rebate Amount")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    trigger OnInit()
    begin
        Clear(index);
    end;
    trigger OnAfterGetRecord()
    Begin
        If index = 0 then
        begin
            CmpReb.Reset;
            CmpReb.Setrange(Campaign,Rec.Campaign);
            CmpReb.findset;
        end;
        index+=1;    
    End;
    procedure Show_Hide(Flg:Boolean)
    Begin
        ShowFlg := Flg;
    End;
 
    var
        ShowFlg:Boolean;
        CmpReb:record "PC Campaign Rebates";
        index:Integer; 
}
