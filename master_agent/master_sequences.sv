



class master_sequence extends uvm_sequence #(trans);

  `uvm_object_utils(master_sequence)

  function new(string name = "master_sequence");

    super.new(name);

  endfunction

endclass

class master_seq extends master_sequence;

  `uvm_object_utils(master_seq)

  function new(string name = "master_seq");

    super.new(name);

  endfunction


  task body();


    req = trans::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {
      AWBURST == 2'b01;
      AWSIZE == 2'b10;
      // ARBURST == 2'b00;
      AWLEN == 3;
      // ARLEN == 5;
    });
    finish_item(req);

  endtask

endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////MULTIPLE OUTSTANDING////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class master1_seq extends master_sequence;

  `uvm_object_utils(master1_seq)

  function new(string name = "master1_seq");

    super.new(name);

  endfunction

  task body();


    req = trans::type_id::create("req");
    start_item(req);
    assert (req.randomize());

    finish_item(req);

  endtask

endclass

class master2_seq extends master_sequence;

  `uvm_object_utils(master2_seq)

  function new(string name = "master2_seq");

    super.new(name);

  endfunction


  task body();

    req = trans::type_id::create("req");
    start_item(req);
    assert (req.randomize());
    finish_item(req);

  endtask

endclass

class master3_seq extends master_sequence;

  `uvm_object_utils(master3_seq)

  function new(string name = "master3_seq");

    super.new(name);

  endfunction

  task body();

    req = trans::type_id::create("req");
    start_item(req);
    assert (req.randomize());
    finish_item(req);

  endtask

endclass

class master4_seq extends master_sequence;

  `uvm_object_utils(master4_seq)

  function new(string name = "master4_seq");

    super.new(name);

  endfunction

  task body();

    req = trans::type_id::create("req");
    start_item(req);
    assert (req.randomize());
    finish_item(req);

  endtask

endclass