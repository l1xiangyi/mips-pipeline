module vector_example;
  reg [3:0] my_vector;

  initial begin
    my_vector = 4'b1010;
    my_vector[3] = 1'b0;
    $display("my_vector = %b", my_vector);
  end
endmodule
