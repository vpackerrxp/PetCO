page 80005 "PC EDI Execution Log"
{
    
    ApplicationArea = All;
    Caption = 'EDI Execution Log';
    PageType = List;
    SourceTable = "PC EDI Execution Log";
    UsageCategory = Lists;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Excution Date/Time"; Rec."Execution Date/Time")
                {
                    ApplicationArea = All;
                }
                field("Purchase Order No."; Rec."Purchase Order No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        PG:PAGE "Purchase Order";
                        PH:Record "Purchase Header";
                    begin
                        if PH.Get(PH."Document Type"::Order,Rec."Purchase Order No.") then
                        begin
                            PG.SetRecord(PH);
                            Pg.Run();   
                        end
                        else
                            Message('PO Not found');
                    end;    
                }
                field(Vendor; Rec.Vendor)
                {
                    ApplicationArea = All;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                }
                field("EDI Execution Action"; Rec."EDI Execution Action")
                {
                    ApplicationArea = All;
                }
                field("Transaction Status";rec."Transaction Status")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
    }
    
    trigger OnOpenPage()
    begin
        Rec.reset;
        Rec.Setfilter("Execution Date/Time",'<=%1',CreateDateTime(CalcDate('-1M',Today),0T));
        If Rec.findset then Rec.DeleteAll();
        Rec.reset;
    end;

}
