clear mex

kBuildFolder = './c++/build';
if (~exist(kBuildFolder, 'dir'))
  mkdir(kBuildFolder);
end;

mex ./c++/cnntrain_mex.cpp ...
    "./c++/sources/*.cpp" ...
    -I"./c++/include/" ...      
    -lut ...
    -outdir ./c++/build ...   
    -largeArrayDims ...
    COMPFLAGS="$COMPFLAGS /openmp" ...
    CXXFLAGS="\$CXXFLAGS -fopenmp" ...
    LDFLAGS="\$LDFLAGS -fopenmp";
disp('cnntrain_mex compiled');  

mex ./c++/cnntrain_inv_mex.cpp ...
    "./c++/sources/*.cpp" ...
    -I"./c++/include/" ...      
    -lut ...
    -outdir ./c++/build ...   
    -largeArrayDims ...
    COMPFLAGS="/openmp $COMPFLAGS" ...
    CXXFLAGS="\$CXXFLAGS -fopenmp" ...
    LDFLAGS="\$LDFLAGS -fopenmp";
disp('cnntrain_inv_mex compiled');

mex ./c++/classify_mex.cpp ...
    "./c++/sources/*.cpp" ...
    -I"./c++/include/" ...      
    -lut ...
    -outdir ./c++/build ...   
    -largeArrayDims ...
    COMPFLAGS="$COMPFLAGS /openmp" ...
    CXXFLAGS="\$CXXFLAGS -fopenmp" ...
    LDFLAGS="\$LDFLAGS -fopenmp";
disp('classify_mex compiled');

mex ./c++/genweights_mex.cpp ...
    "./c++/sources/*.cpp" ...
    -I"./c++/include/" ...      
    -lut ...
    -outdir ./c++/build ...   
    -largeArrayDims ...
    COMPFLAGS="$COMPFLAGS /openmp" ...
    CXXFLAGS="\$CXXFLAGS -fopenmp" ...
    LDFLAGS="\$LDFLAGS -fopenmp";
disp('genweights_mex compiled');
