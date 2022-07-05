page 80029 "PC Adjust Inventory"
{
    Caption = 'Adjust Inventory';
    DataCaptionExpression = Item."No." + ' - ' + Item.Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = Location;
    SourceTableView = where("Use As In-Transit"=const(False),Code=filter('<>QC'));

    layout
    {
        area(content)
        {
            repeater(Control5)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field(Name; rec.Name)
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("INV"; Item.Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Current Inventory';
                    Editable = false;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                }
                field(NewInventory; TempItemJournalLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Inventory';
                    DecimalPlaces = 0 : 5;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the inventory quantity that will be recorded for the item when you choose the OK button.';

                    trigger OnValidate()
                    begin
                        TempItemJournalLine.Modify();
                    end;
                }
                field(BaseUnitofMeasure; Item."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Unit of Measure';
                    Editable = false;
                    ToolTip = 'Specifies the unit in which the item is held in inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
               field(ReasonCode; TempItemJournalLine."Return Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reason Code';
                    TableRelation = "Reason Code";
                    trigger OnValidate()
                    begin
                        TempItemJournalLine.Modify();
                    end;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        Item.SetFilter("Location Filter", '%1', rec.Code);
        Item.CalcFields(Inventory);
        TempItemJournalLine.SetRange("Location Code", rec.Code);
        TempItemJournalLine.FindFirst;
    end;

    trigger OnOpenPage()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LineNo: Integer;
    begin
        Rec.FindSet;
        repeat
            TempItemJournalLine.Init();
            Item.SetFilter("Location Filter", '%1', Rec.Code);
            Item.CalcFields(Inventory);
            TempItemJournalLine."Line No." := LineNo;
            TempItemJournalLine.Quantity := Item.Inventory;
            TempItemJournalLine."Item No." := Item."No.";
            TempItemJournalLine."Location Code" := Rec.Code;
            TempItemJournalLine.Insert();
            LineNo += 1;
        until Rec.Next = 0;
        Rec.FindFirst;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
       ErrorText: Text;
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then 
        begin
            TempItemJournalLine.Reset();
            ErrorText := PostMultipleAdjustmentsToItemLedger(TempItemJournalLine);
            if ErrorText <> '' then
                Message(ErrorText);
        end;
    end;
    procedure SetItem(ItemNo: Code[20])
    begin
        Item.Get(ItemNo);
    end;
    local procedure PostMultipleAdjustmentsToItemLedger(var TempItemJournalLine: Record "Item Journal Line" temporary) LastErrorText: Text
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemTemplate: Code[10];
        ItemBatch: Code[10];
        Cu:Codeunit "Adjust Item Inventory";

    begin
        if not TempItemJournalLine.FindSet then
            exit;

        ItemTemplate := CU.SelectItemTemplateForAdjustment;
        ItemBatch := CreateItemBatch(ItemTemplate);

        repeat
            Item.Get(TempItemJournalLine."Item No.");
            Item.SetFilter("Location Filter", '%1', TempItemJournalLine."Location Code");
            Item.CalcFields(Inventory);
            if Item.Inventory <> TempItemJournalLine.Quantity then 
            begin
                cu.CreateItemJnlLine(ItemJnlLine, Item, ItemTemplate, ItemBatch, TempItemJournalLine.Quantity);
                ItemJnlLine.Validate("Line No.", TempItemJournalLine."Line No.");
                ItemJnlLine.Validate("Location Code", TempItemJournalLine."Location Code");
                ItemJnlLine."Return Reason Code" := TempItemJournalLine."Return Reason Code";
                ItemJnlLine.Insert(true);
            end;
        until TempItemJournalLine.Next = 0;

        ItemJnlLine.SetRange("Journal Template Name", ItemTemplate);
        ItemJnlLine.SetRange("Journal Batch Name", ItemBatch);
        if ItemJnlLine.IsEmpty then
            exit;
        LastErrorText := Cu.PostItemJnlLines(ItemJnlLine);
    end;
    local procedure CreateItemBatch(TemplateName: Code[10]): Code[10]
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        ItemJnlBatch.Init();
        ItemJnlBatch."Journal Template Name" := TemplateName;
        ItemJnlBatch.Name := CreateBatchName;
        ItemJnlBatch.Description := SimpleInvJnlNameTxt;
        ItemJnlBatch.Insert();
        exit(ItemJnlBatch.Name);
    end;
    local procedure CreateBatchName(): Code[10]
    var
        BatchName: Text;
    begin
        BatchName := Format(CreateGuid);
        exit(CopyStr(BatchName, 2, 10));
    end;

    var
        Item: Record Item;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        SimpleInvJnlNameTxt: Label 'DEFAULT', Comment = 'The default name of the item journal';
    
}

