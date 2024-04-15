let config: UIConfig.t = {
  primaryColor: "primary",
  backgroundColor: "bg-primary",
  button: {
    height: {
      medium: "h-fit",
      xSmall: "h-fit",
      small: "h-fit",
    },
    padding: {
      xSmall: "py-3 px-4",
      small: "py-3 px-4",
      smallPagination: "py-3 px-4 mr-1",
      smallDropdown: "py-3 px-4",
      medium: "py-3 px-4",
      mediumPagination: "py-3 px-4 mr-1",
      large: "py-3 px-4",
      xSmallText: "px-1",
      smallText: "px-1",
      mediumText: "px-1",
      largeText: "px-1",
    },
    border: {
      borderFirstWidthClass: "border focus:border-r",
      borderLastWidthClass: "border  focus:border-l",
      borderPrimaryOutlineBorderStyleClass: "border-1",
      borderSecondaryLoadingBorderStyleClass: "border-border_gray",
      borderSecondaryBorderStyleClass: "border-border_gray border-opacity-20 dark:border-jp-gray-960 dark:border-opacity-100",
    },
    backgroundColor: {
      primaryNormal: "bg-primary hover:bg-primary-hover focus:outline-none",
      primaryDisabled: "bg-primary opacity-60 dark:bg-jp-gray-950 dark:bg-opacity-50 border dark:border-jp-gray-disabled_border dark:border-opacity-50",
      primaryNoHover: "bg-primary hover:bg-primary-hover focus:outline-none dark:text-opacity-50 text-opacity-50",
      primaryLoading: "bg-primary",
      primaryOutline: "mix-blend-normal",
      paginationNormal: "border-left-1 opacity-80 border-right-1 font-normal border-left-1 text-jp-gray-900 text-opacity-50 hover:text-jp-gray-900 focus:outline-none",
      paginationLoading: "border-left-1 border-right-1 font-normal border-left-1 bg-jp-gray-200 dark:bg-jp-gray-800 dark:bg-opacity-10",
      paginationDisabled: "border-left-1 border-right-1 font-normal border-left-1 bg-jp-gray-300 dark:bg-jp-gray-950 dark:bg-opacity-50 border dark:border-jp-gray-disabled_border dark:border-opacity-50",
      paginationNoHover: "bg-white border-left-1 border-right-1 font-normal text-jp-gray-900 text-opacity-75 hover:text-jp-gray-900 dark:text-jp-gray-text_darktheme dark:text-opacity-75",
      dropdownDisabled: "bg-gray-200 dark:bg-jp-gray-950 dark:bg-opacity-50 border dark:border-jp-gray-disabled_border dark:border-opacity-50",
      secondaryNormal: "bg-jp-gray-button_gray text-jp-gray-900 text-opacity-75 hover:bg-jp-gray-secondary_hover hover:text-jp-gray-890  dark:bg-jp-gray-darkgray_background  dark:text-jp-gray-text_darktheme dark:text-opacity-50 focus:outline-none",
      secondaryLoading: "bg-jp-gray-button_gray  dark:bg-jp-gray-darkgray_background",
      secondaryNoHover: "bg-jp-gray-button_gray text-jp-gray-900 text-opacity-50  hover:bg-jp-gray-secondary_hover hover:text-jp-gray-890  dark:bg-jp-gray-darkgray_background dark:text-jp-gray-text_darktheme focus:outline-none dark:text-opacity-50 ",
    },
    borderRadius: {
      default: "rounded",
      defaultPagination: "rounded-md",
    },
    textColor: {
      primaryNormal: "text-white",
      primaryOutline: "text-blue-500",
      primaryDisabled: "text-jp-gray-600 dark:text-jp-gray-text_darktheme dark:text-opacity-25",
    },
  },
  font: {
    textColor: {
      primaryNormal: "text-primary",
    },
  },
  shadow: {
    shadowColor: {
      primaryNormal: "focus:shadow-primary",
      primaryFocused: "focus:shadow-primary",
    },
  },
  border: {
    borderColor: {
      primaryNormal: "border border-primary",
      primaryFocused: "focus:border-primary",
    },
  },
  sidebarColor: {
    backgroundColor: {
      primaryNormal: "bg-primary-sidebar",
    },
  },
}
