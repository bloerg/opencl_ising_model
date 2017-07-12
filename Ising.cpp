
#include <iostream>
#include <fstream>

#define __CL_ENABLE_EXCEPTIONS
#include <CL/cl2.hpp>

int main() {
    std::vector<cl::Platform> all_platforms;
    cl::Platform::get(&all_platforms);
    if (all_platforms.size() == 0) {
        std::cout << "No platforms found. Check OpenCL installation!\n";
        exit(1);
    }
    cl::Platform default_platform=all_platforms[0];
    std::cout << "Using platform: "<<default_platform.getInfo<CL_PLATFORM_NAME>()<<"\n";
    
    std::vector<cl::Device> all_devices;
    default_platform.getDevices(CL_DEVICE_TYPE_ALL, &all_devices);
    if (all_devices.size() == 0) {
        std::cout << "No devices found. Check OpenCL installation!\n";
        exit(1);
    }
    
    //Use CPU (1) or GPU (0)
    cl::Device default_device = all_devices[1];
    std::cout << "Using device: " << default_device.getInfo<CL_DEVICE_NAME>() << "\n";
    
    
    cl::Context context({default_device});
    
    // read the kernel from source file
    std::ifstream ising_kernel_file("Ising.cl");
    std::string ising_kernel(
        std::istreambuf_iterator<char>(ising_kernel_file),
        (std::istreambuf_iterator<char>())
    );
    
    //see http://github.khronos.org/OpenCL-CLHPP/
    std::vector<std::string> program_strings {ising_kernel};
    
    cl::Program ising_program(program_strings);
    
    try {
        ising_program.build("-cl-std=CL2.0");
    }
    catch (...) {
        // Print build info for all devices
        cl_int build_err = CL_SUCCESS;
        auto build_info = ising_program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(&build_err);
        for (auto &pair : build_info) {
            std::cerr << pair.second << std::endl << std::endl;
        }
        return 1;
    }
    

    
}
