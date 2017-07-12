
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
    cl::Device device = all_devices[1];
    std::cout << "Using device: " << device.getInfo<CL_DEVICE_NAME>() << "\n";
    
    
    cl::Context context({device});
    
    // read the kernel from source file
    std::ifstream ising_kernel_file("Ising.cl");
    std::string ising_kernel_string(
        std::istreambuf_iterator<char>(ising_kernel_file),
        (std::istreambuf_iterator<char>())
    );
    
    //see http://github.khronos.org/OpenCL-CLHPP/
    std::vector<std::string> program_strings {ising_kernel_string};
    
    cl::Program ising_program(context, ising_kernel_string, true);
    
    //~ try {
        //~ ising_program.build("-cl-std=CL2.0");
        
    //~ }
    //~ catch (...) {
        //~ // Print build info for all devices
        //~ cl_int build_err = CL_SUCCESS;
        //~ auto build_info = ising_program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(&build_err);
        //~ for (auto &pair : build_info) {
            //~ std::cerr << pair.second << std::endl << std::endl;
        //~ }
        //~ return 1;
    //~ }
    
    if (ising_program.build({ device }) != CL_SUCCESS){
        std::cout << " Error building: " << ising_program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(device) << "\n";
        getchar();
        exit(1);
    }
    
        //~ char lattice[16];
        //~ cl::Buffer lattice_buffer(context, CL_MEM_WRITE_ONLY | CL_MEM_HOST_READ_ONLY, sizeof(lattice));
        //~ cl::Kernel ising_kernel(ising_program, "Ising", &err);
        //~ ising_kernel.setArg(0, lattice_buffer);
        
        //~ cl::CommandQueue queue(context, device);
        
        //~ queue.enqueueReadBuffer(lattice_buffer, CL_TRUE, 0, sizeof(lattice), lattice);
        //~ std::cout << lattice;
        //~ std::cin.get(); // wait for keypress
    
        char lattice[16];
    
        cl::Buffer lattice_buffer(context, CL_MEM_WRITE_ONLY | CL_MEM_HOST_READ_ONLY, sizeof(lattice));
        cl::CommandQueue queue(context, device);
        
        
        cl::Kernel ising_kernel(ising_program, "ising");
        ising_kernel.setArg(0, lattice_buffer);
        
        //~ queue.enqueueNDRangeKernel(ising_kernel, cl::NullRange, cl::NullRange, cl::NullRange);
        queue.enqueueNDRangeKernel(ising_kernel, cl::NDRange(0), cl::NDRange(10), cl::NDRange(1));

        queue.enqueueReadBuffer(lattice_buffer, CL_TRUE, 0, sizeof(lattice), lattice);
        std::cout << lattice;
        std::cin.get(); // wait for keypress

}
