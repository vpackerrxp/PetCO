page 80042 "PC Campaign Rebates"
{
    ApplicationArea = All;
    Caption = 'Campaign Rebates';
    PageType = Worksheet;
    SourceTable = "PC Campaign Rebates";
    UsageCategory = Tasks;
    InsertAllowed = false;
    ModifyAllowed = false;
    
    layout
    {
        area(content)
        {
            Group(Filters)
            {
                field("Rebate Vendor Filter";Supp)
                {
                    ApplicationArea = All;
                    TableRelation = Vendor."No." where("No."=filter('SUP*'));
                    trigger OnValidate()
                    Begin
                        Setfilters();
                    End;
                    trigger OnAssistEdit()
                    begin
                       Clear(Supp);
                       Setfilters();
                    end;
                }
                field("Campaign Filter";Camp)
                {
                   ApplicationArea = All;
                   TableRelation = "PC Campaign Rebates".Campaign;
                    trigger OnValidate()
                    Begin
                        Setfilters();
                    End;
                    trigger OnAssistEdit()
                    begin
                       Clear(Camp);
                       Setfilters();
                    end;
                }
            }
            Group(process)
            {
                Field("Export Template Type";TempType)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                Field("A";'Export Campaign Data Template')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "PC Import Export Routines";
                    begin
                        If Confirm(StrsubStno('Export Campaign Template as Type %1',TempType),True) then
                            Cu.Export_Campaign_Template(TempType);
                    end;    
                }
                Field("B";'Import Campaign Data')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "PC Import Export Routines";
                    begin
                        Cu.Import_Campaign_Rebates();
                    end;    
                }
            }
            repeater(General)
            {
                field("Rebate Type"; Rec."Rebate Type")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Rebate Supplier No."; Rec."Rebate Supplier No.")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        CU:Codeunit "PC Import Export Routines";
                    begin
                        If Confirm('Do you wish to Export this Campaign Data Now?') then
                            Cu.Export_Campaign_Data(Rec.Campaign);
                    end;
                }
                field(Campaign; Rec.Campaign)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Campaign Start Date"; Rec."Campaign Start Date")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Campaign End Date"; Rec."Campaign End Date")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Campaign SKUs";rec."Campaign SKUs")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        CSku:record "PC Campaign SKU";
                        PG:Page "PC Campaign SKU";
                    begin
                        CSku.reset;
                        CSku.Setrange(Campaign,Rec.Campaign);
                        If CSku.Findset then
                        begin
                            Pg.SetTableView(CSku);
                            Pg.Show_Hide(Rec."Rebate Type" = Rec."Rebate Type"::Campaign);
                            Pg.RunModal();
                        end;     
                    end;
                 }
            }
        }
    }
    trigger OnClosePage()
    Var 
        CmpReb:Record "PC Campaign Rebates";
    begin
        //Clean up of Campaigns once they are done
        CmpReb.Reset;
        CmpReb.SetRange("Rebate Type",CmpReb."Rebate Type"::Campaign);
        CmpReb.Setfilter("Campaign End Date",'<=%1',Calcdate('-10D',Today));
        If CmpReb.findSet then CmpReb.DeleteAll(true);
    end;
    local procedure Setfilters();
    begin
        Rec.Reset();
        IF Supp <> '' then Rec.Setrange("Rebate Supplier No.",Supp);
        If Camp <> '' then Rec.Setrange(Campaign,Camp);
        CurrPage.update(false);
    end;
    procedure Show_Hide(Flg:Boolean)
    Begin
        ShowFlg := Flg;
    End;

    var
        Supp:code[20];
        Camp:code[20];
        TempType:Option Campaign,"Auto Delivery";
        ShowFlg:Boolean;
}
